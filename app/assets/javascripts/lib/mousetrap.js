// This is the only file allowed to import directly from the package.
// eslint-disable-next-line no-restricted-imports
import Mousetrap from 'mousetrap';

const additionalStopCallbacks = [];
const originalStopCallback = Mousetrap.prototype.stopCallback;

Mousetrap.prototype.stopCallback = function customStopCallback(e, element, combo) {
  for (const callback of additionalStopCallbacks) {
    const returnValue = callback.call(this, e, element, combo);
    if (returnValue !== undefined) return returnValue;
  }

  return originalStopCallback.call(this, e, element, combo);
};

/**
 * Add a stop callback to Mousetrap.
 *
 * This allows overriding the default behaviour of Mousetrap#stopCallback,
 * which is to stop the bound key handler/callback from being called if the key
 * combo is pressed inside form fields (input, select, textareas, etc). See
 * https://craig.is/killing/mice#api.stopCallback.
 *
 * The stopCallback registered here has the same signature as
 * Mousetrap#stopCallback, with the one difference being that the callback
 * should return `undefined` if it has no opinion on whether the current key
 * combo should be stopped or not, and the next stop callback should be
 * consulted instead. If a boolean is returned, no other stop callbacks are
 * called.
 *
 * Note: This approach does not always work as expected when coupled with
 * Mousetrap's pause plugin, which is used for enabling/disabling all keyboard
 * shortcuts. That plugin assumes it's the first to execute and overwrite
 * Mousetrap's `stopCallback` method, whereas to work correctly with this, it
 * must execute last. This is not guaranteed or even attempted.
 *
 * To work correctly, we may need to reimplement the pause plugin here.
 *
 * @param {(e: Event, element: Element, combo: string) => boolean|undefined}
 *     stopCallback The additional stop callback function to add to the chain
 *     of stop callbacks.
 * @returns {void}
 */
export const addStopCallback = (stopCallback) => {
  // Unshift, since we want to iterate through them in reverse order, so that
  // the most recently added handler is called first, and the original
  // stopCallback method is called last.
  additionalStopCallbacks.unshift(stopCallback);
};

/**
 * Clear additionalStopCallbacks. Used only for tests.
 */
export const clearStopCallbacksForTests = () => {
  additionalStopCallbacks.length = 0;
};

export const MOUSETRAP_COPY_KEYBOARD_SHORTCUT = 'mod+c';

export { Mousetrap };
