export const BACKGROUND_REQUEST_HEADER = 'X-GitLab-Background-Request';
export const IDLE_THRESHOLD_MS = 60 * 1000;

const ACTIVITY_EVENTS = ['pointerdown', 'pointermove', 'keydown', 'wheel', 'scroll'];

// Loading the page is a navigation, so it counts as activity.
let lastActivityAt = performance.now();

const recordActivity = () => {
  lastActivityAt = performance.now();
};

// Capture phase, so `scroll` on any element (it does not bubble) is seen too.
ACTIVITY_EVENTS.forEach((event) =>
  window.addEventListener(event, recordActivity, { capture: true, passive: true }),
);

/**
 * To only be used for testing purposes.
 *
 * @param {number} timestamp The time of the last user activity, as from `performance.now()`.
 */
export const setLastActivityAtForTestsOnly = (timestamp) => {
  lastActivityAt = timestamp;
};

/**
 * Returns whether the user has not interacted with the page for IDLE_THRESHOLD_MS.
 * Requests sent while idle are polls or background fetches, so the backend does not
 * let them extend the session.
 *
 * @returns {boolean}
 */
export const isUserIdle = () => performance.now() - lastActivityAt >= IDLE_THRESHOLD_MS;
