// This is the only file allowed to import directly from the package.
// eslint-disable-next-line no-restricted-imports
import Mousetrap from 'mousetrap';
import { keyboardShortcutsDisabled } from '~/behaviors/shortcuts/shortcuts_disabled';

const additionalStopCallbacks = [];
const originalStopCallback = Mousetrap.prototype.stopCallback;

// Counted, not boolean: user preferences and Zen mode pause independently.
let pauseCount = 0;

Mousetrap.prototype.stopCallback = function customStopCallback(e, element, combo) {
  // Before the chain: a callback returning a boolean ends the loop, skipping a check placed inside.
  if (pauseCount > 0) return true;

  for (const callback of additionalStopCallbacks) {
    const returnValue = callback.call(this, e, element, combo);
    if (returnValue !== undefined) return returnValue;
  }

  return originalStopCallback.call(this, e, element, combo);
};

/**
 * Suppress every Mousetrap shortcut until each caller that paused has unpaused.
 *
 * Bindings stay registered; they are short-circuited while paused.
 */
Mousetrap.pause = () => {
  pauseCount += 1;
};

/** Lift one caller's suppression. Shortcuts resume once every caller has unpaused. */
Mousetrap.unpause = () => {
  // Floored so a stray unpause cannot resume shortcuts another caller still needs suppressed.
  pauseCount = Math.max(0, pauseCount - 1);
};

/** Resets the pause count. Used only for tests. */
export const clearPausesForTests = () => {
  pauseCount = 0;
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
 * Note: a stop callback cannot re-enable a shortcut while paused. `Mousetrap.pause` is checked
 * before this chain runs, so returning `false` here has no effect until every caller has unpaused.
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

// ---------------------------------------------------------------------------
// Input focus lock
//
// Suppresses all Mousetrap shortcuts for a short window after a user action
// that asynchronously mounts and focuses an input. This prevents keystrokes
// typed during the mount-to-focus gap from accidentally triggering global
// shortcuts (e.g. clicking "Reply" and starting to type before the editor
// has been mounted and focused).
// ---------------------------------------------------------------------------

const INPUT_FOCUS_LOCK_DEFAULT_TIMEOUT_MS = 500;

let inputFocusLockSuppressed = false;
let inputFocusLockTimeoutId = null;

const onFocusIn = (event) => {
  const { target } = event;
  if (
    target instanceof HTMLInputElement ||
    target instanceof HTMLTextAreaElement ||
    target instanceof HTMLSelectElement ||
    (target instanceof HTMLElement && target.isContentEditable)
  ) {
    // eslint-disable-next-line no-use-before-define
    releaseInputFocusLock();
  }
};

function releaseInputFocusLock() {
  inputFocusLockSuppressed = false;
  if (inputFocusLockTimeoutId !== null) {
    clearTimeout(inputFocusLockTimeoutId);
    inputFocusLockTimeoutId = null;
  }
  document.removeEventListener('focusin', onFocusIn);
}

let inputFocusLockInitialized = false;

const ensureInputFocusLockInitialized = () => {
  if (inputFocusLockInitialized) return;
  inputFocusLockInitialized = true;
  addStopCallback(() => (inputFocusLockSuppressed ? true : undefined));
};

/**
 * Suppress all Mousetrap shortcuts for a short window after a user action
 * that asynchronously mounts and focuses an input.
 *
 * Call this from any handler that opens a comment editor, command palette,
 * sidebar dropdown, or similar surface where the input is not focused
 * synchronously. Keystrokes typed during the mount-to-focus gap will not
 * invoke global shortcuts.
 *
 * The lock holds until an input element receives focus, or until the safety
 * timeout elapses, whichever comes first. If the UI takes longer than the
 * timeout, keystrokes are dropped rather than rescued; the underlying
 * problem is the slow mount.
 *
 * Repeated calls reset the release timer. The first call also registers the
 * lock's stop callback with Mousetrap.
 */
export const suppressShortcutsUntilInputFocus = ({
  timeoutMs = INPUT_FOCUS_LOCK_DEFAULT_TIMEOUT_MS,
} = {}) => {
  if (keyboardShortcutsDisabled()) return;

  ensureInputFocusLockInitialized();
  inputFocusLockSuppressed = true;
  if (inputFocusLockTimeoutId !== null) clearTimeout(inputFocusLockTimeoutId);
  inputFocusLockTimeoutId = setTimeout(releaseInputFocusLock, timeoutMs);
  document.addEventListener('focusin', onFocusIn);
};

export const resetInputFocusLockForTests = () => {
  releaseInputFocusLock();
  inputFocusLockInitialized = false;
};

export { Mousetrap };
