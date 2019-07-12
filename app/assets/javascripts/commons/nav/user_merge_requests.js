import Api from '~/api';

let channel;

function broadcastCount(newCount) {
  if (!channel) {
    return;
  }

  channel.postMessage(newCount);
}

function updateUserMergeRequestCounts(newCount) {
  const mergeRequestsCountEl = document.querySelector('.merge-requests-count');
  mergeRequestsCountEl.textContent = newCount.toLocaleString();
  mergeRequestsCountEl.classList.toggle('hidden', Number(newCount) === 0);
}

/**
 * Refresh user counts (and broadcast if open)
 */
export function refreshUserMergeRequestCounts() {
  return Api.userCounts()
    .then(({ data }) => {
      const count = data.merge_requests;

      updateUserMergeRequestCounts(count);
      broadcastCount(count);
    })
    .catch(ex => {
      console.error(ex); // eslint-disable-line no-console
    });
}

/**
 * Close the broadcast channel for user counts
 */
export function closeUserCountsBroadcast() {
  if (!channel) {
    return;
  }

  channel.close();
  channel = null;
}

/**
 * Open the broadcast channel for user counts, adds user id so we only update
 *
 * **Please note:**
 * Not supported in all browsers, but not polyfilling for now
 * to keep bundle size small and
 * no special functionality lost except cross tab notifications
 */
export function openUserCountsBroadcast() {
  closeUserCountsBroadcast();

  if (window.BroadcastChannel) {
    const currentUserId = typeof gon !== 'undefined' && gon && gon.current_user_id;
    if (currentUserId) {
      channel = new BroadcastChannel(`mr_count_channel_${currentUserId}`);
      channel.onmessage = ev => {
        updateUserMergeRequestCounts(ev.data);
      };
    }
  }
}
