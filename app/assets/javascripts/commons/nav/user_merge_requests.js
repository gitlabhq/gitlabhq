import { getUserCounts } from '~/rest_api';

let channel;

function broadcastCount(newCount) {
  if (!channel) {
    return;
  }

  channel.postMessage(newCount);
}

function updateUserMergeRequestCounts(newCount) {
  const mergeRequestsCountEl = document.querySelector('.js-assigned-mr-count');
  mergeRequestsCountEl.textContent = newCount.toLocaleString();
}

function updateReviewerMergeRequestCounts(newCount) {
  const mergeRequestsCountEl = document.querySelector('.js-reviewer-mr-count');
  mergeRequestsCountEl.textContent = newCount.toLocaleString();
}

function updateMergeRequestCounts(newCount) {
  const mergeRequestsCountEl = document.querySelector('.js-merge-requests-count');
  mergeRequestsCountEl.textContent = newCount.toLocaleString();
  mergeRequestsCountEl.classList.toggle('gl-display-none', Number(newCount) === 0);
}

/**
 * Refresh user counts (and broadcast if open)
 */
export function refreshUserMergeRequestCounts() {
  if (gon?.use_new_navigation) {
    // The new sidebar manages _all_ the counts in
    // ~/super_sidebar/user_counts_manager.js
    document.dispatchEvent(new CustomEvent('userCounts:fetch'));
    return Promise.resolve();
  }
  return getUserCounts()
    .then(({ data }) => {
      const assignedMergeRequests = data.assigned_merge_requests;
      const reviewerMergeRequests = data.review_requested_merge_requests;
      const fullCount = assignedMergeRequests + reviewerMergeRequests;

      updateUserMergeRequestCounts(assignedMergeRequests);
      updateReviewerMergeRequestCounts(reviewerMergeRequests);
      updateMergeRequestCounts(fullCount);
      broadcastCount(fullCount);
    })
    .catch((ex) => {
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
  if (gon?.use_new_navigation) {
    // The new sidebar broadcasts _all counts_ and updates
    // them accordingly. Therefore we do not need this manager
    // ~/super_sidebar/user_counts_manager.js
    return;
  }
  closeUserCountsBroadcast();

  if (window.BroadcastChannel) {
    const currentUserId = typeof gon !== 'undefined' && gon && gon.current_user_id;
    if (currentUserId) {
      channel = new BroadcastChannel(`mr_count_channel_${currentUserId}`);
      channel.onmessage = (ev) => {
        updateMergeRequestCounts(ev.data);
      };
    }
  }
}
