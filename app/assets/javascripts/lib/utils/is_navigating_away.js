let navigating = false;

window.addEventListener('beforeunload', () => {
  navigating = true;
});

/**
 * To only be used for testing purposes. Allows the navigating state to be set
 * to a given value.
 *
 * @param {boolean} value The value to set the navigating flag to.
 */
export const setNavigatingForTestsOnly = (value) => {
  navigating = value;
};

/**
 * Returns a boolean indicating whether the browser is in the process of
 * navigating away from the current page.
 *
 * @returns {boolean}
 */
export const isNavigatingAway = () => navigating;
