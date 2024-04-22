import Vue from 'vue';
import { getUserCounts } from '~/api/user_api';

export const userCounts = Vue.observable({
  last_update: 0,
  // The following fields are part of
  // https://docs.gitlab.com/ee/api/users.html#user-counts
  todos: 0,
  assigned_issues: 0,
  assigned_merge_requests: 0,
  review_requested_merge_requests: 0,
});

function updateCounts(payload = {}) {
  if ((payload.last_update ?? 0) < userCounts.last_update) {
    return;
  }
  for (const key in userCounts) {
    if (Number.isInteger(payload[key])) {
      userCounts[key] = payload[key];
    }
  }
}

let broadcastChannel = null;

function broadcastUserCounts(data) {
  broadcastChannel?.postMessage(data);
}

async function retrieveUserCountsFromApi() {
  try {
    const lastUpdate = Date.now();
    const { data } = await getUserCounts();
    const payload = { ...data, last_update: lastUpdate };
    updateCounts(payload);
    broadcastUserCounts(userCounts);
  } catch (e) {
    // eslint-disable-next-line no-console, @gitlab/require-i18n-strings
    console.error('Error retrieving user counts', e);
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
  document.removeEventListener('userCounts:fetch', retrieveUserCountsFromApi);
  document.removeEventListener('todo:toggle', updateTodos);
  broadcastChannel?.close();
  broadcastChannel = null;
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

  if (window.BroadcastChannel && gon?.current_user_id) {
    broadcastChannel = new BroadcastChannel(`user_counts_${gon?.current_user_id}`);
    broadcastChannel.onmessage = (ev) => {
      updateCounts(ev.data);
    };
    broadcastUserCounts(userCounts);
  }
}
