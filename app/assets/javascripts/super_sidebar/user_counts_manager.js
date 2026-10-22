import { observable } from '~/lib/utils/observable';
import { pageSingleton } from '~/lib/utils/page_singleton';
import { getUserCounts } from '~/api/user_api';
import { getStorageValue, saveStorageValue } from '~/lib/utils/local_storage';

export const userCounts = observable('super_sidebar_user_counts', {
  last_update: 0,
  // The following fields are part of
  // https://docs.gitlab.com/ee/api/users.html#user-counts
  todos: 0,
  assigned_issues: 0,
  assigned_merge_requests: 0,
  review_requested_merge_requests: 0,
  get total_merge_requests() {
    return this.assigned_merge_requests + this.review_requested_merge_requests;
  },
});

const computed = ['total_merge_requests'];

function updateCounts(payload = {}) {
  if ((payload.last_update ?? 0) < userCounts.last_update) {
    return;
  }
  for (const key in userCounts) {
    if (!computed.includes(key) && Number.isInteger(payload[key])) {
      userCounts[key] = payload[key];
    }
  }
}

// The hybrid Vue 2/Vue 3 build compiles this module once per lane, so listener
// references are per-copy. The active registration is shared, so destroy can
// tear down the other copy's.
const holder = pageSingleton('user_counts_manager', () => ({ registration: null }));

function broadcastUserCounts(data) {
  holder.registration?.broadcastChannel?.postMessage({ ...data });
}

export function useCachedUserCounts() {
  const cachedUserCounts = getStorageValue('user_counts').value;

  if (!cachedUserCounts) return;

  updateCounts({ ...cachedUserCounts, last_update: Date.now() });
  broadcastUserCounts(cachedUserCounts);
}

export async function retrieveUserCountsFromApi() {
  try {
    const lastUpdate = Date.now();
    const { data } = await getUserCounts();
    const payload = { ...data, last_update: lastUpdate };
    saveStorageValue('user_counts', payload);
    updateCounts(payload);
    broadcastUserCounts(userCounts);
  } catch (e) {
    useCachedUserCounts();

    if (e) {
      // eslint-disable-next-line no-console, @gitlab/require-i18n-strings
      console.error('Error retrieving user counts', e);
    }
  }
}

function updateTodos(e) {
  if (Number.isSafeInteger(e?.detail?.count)) {
    userCounts.todos = Math.max(e.detail.count, 0);
  } else if (Number.isSafeInteger(e?.detail?.delta)) {
    userCounts.todos = Math.max(userCounts.todos + e.detail.delta, 0);
  }
}

export function destroyUserCountsManager() {
  // Fall back to this copy's own references so removal is attempted even
  // when nothing registered, matching the previous behavior.
  const { registration } = holder;
  document.removeEventListener(
    'userCounts:fetch',
    registration?.retrieveUserCountsFromApi ?? retrieveUserCountsFromApi,
  );
  document.removeEventListener('todo:toggle', registration?.updateTodos ?? updateTodos);
  registration?.broadcastChannel?.close();
  holder.registration = null;
}

/**
 * The createUserCountsManager does three things:
 * 1. Set the initial state of userCounts
 * 2. Create a broadcast channel to communicate user count updates across tabs
 * 3. Add event listeners for other parts in the app which:
 *     - Update todos
 *     - Trigger a refetch of all counts
 */
export function createUserCountsManager() {
  destroyUserCountsManager();
  document.addEventListener('userCounts:fetch', retrieveUserCountsFromApi);
  document.addEventListener('todo:toggle', updateTodos);

  const registration = { retrieveUserCountsFromApi, updateTodos, broadcastChannel: null };
  holder.registration = registration;

  if (window.BroadcastChannel && gon?.current_user_id) {
    registration.broadcastChannel = new BroadcastChannel(`user_counts_${gon?.current_user_id}`);
    registration.broadcastChannel.onmessage = (ev) => {
      updateCounts(ev.data);
    };
    broadcastUserCounts(userCounts);
  }
}

/**
 * EXACT update of the user to-do count. Only use this one, if you got the new
 * to-count returned by an API. Will also broadcast the current count to
 * all other open tabs
 *
 * @param {number} count
 */
export const setGlobalTodoCount = (count) => {
  if (Number.isSafeInteger(count) && count >= 0) {
    userCounts.todos = count;
    broadcastUserCounts({ todos: userCounts.todos, last_update: Date.now() });
  }
};
