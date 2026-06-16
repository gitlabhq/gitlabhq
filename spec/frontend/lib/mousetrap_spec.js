// eslint-disable-next-line no-restricted-imports
import Mousetrap from 'mousetrap';

const originalMethodReturnValue = {};
// Create a mock stopCallback method before ~/lib/utils/mousetrap overwrites
// it. This allows us to spy on calls to it.
const mockOriginalStopCallbackMethod = jest.fn().mockReturnValue(originalMethodReturnValue);
Mousetrap.prototype.stopCallback = mockOriginalStopCallbackMethod;

describe('mousetrap utils', () => {
  describe('addStopCallback', () => {
    let addStopCallback;
    let clearStopCallbacksForTests;
    const mockMousetrapInstance = { isMockMousetrap: true };
    const mockKeyboardEvent = { type: 'keydown', key: 'Enter' };
    const mockCombo = 'enter';

    const mockKeydown = ({
      instance = mockMousetrapInstance,
      event = mockKeyboardEvent,
      element = document,
      combo = mockCombo,
    } = {}) => Mousetrap.prototype.stopCallback.call(instance, event, element, combo);

    beforeEach(async () => {
      // Import async since it mutates the Mousetrap instance, by design.
      ({ addStopCallback, clearStopCallbacksForTests } = await import('~/lib/mousetrap'));
      clearStopCallbacksForTests();
    });

    it('delegates to the original stopCallback method when no additional callbacks added', () => {
      const returnValue = mockKeydown();

      expect(mockOriginalStopCallbackMethod).toHaveBeenCalledTimes(1);

      const [thisArg] = mockOriginalStopCallbackMethod.mock.contexts;
      const [eventArg, element, combo] = mockOriginalStopCallbackMethod.mock.calls[0];

      expect(thisArg).toBe(mockMousetrapInstance);
      expect(eventArg).toBe(mockKeyboardEvent);
      expect(element).toBe(document);
      expect(combo).toBe(mockCombo);

      expect(returnValue).toBe(originalMethodReturnValue);
    });

    it('passes the expected arguments to the given stop callback', () => {
      const callback = jest.fn();

      addStopCallback(callback);

      mockKeydown();

      expect(callback).toHaveBeenCalledTimes(1);

      const [thisArg] = callback.mock.contexts;
      const [eventArg, element, combo] = callback.mock.calls[0];

      expect(thisArg).toBe(mockMousetrapInstance);
      expect(eventArg).toBe(mockKeyboardEvent);
      expect(element).toBe(document);
      expect(combo).toBe(mockCombo);
    });

    describe.each([true, false])('when a stop handler returns %p', (stopCallbackReturnValue) => {
      let methodReturnValue;
      const stopCallback = jest.fn().mockReturnValue(stopCallbackReturnValue);

      beforeEach(() => {
        addStopCallback(stopCallback);

        methodReturnValue = mockKeydown();
      });

      it(`returns ${stopCallbackReturnValue}`, () => {
        expect(methodReturnValue).toBe(stopCallbackReturnValue);
      });

      it('calls stop callback', () => {
        expect(stopCallback).toHaveBeenCalledTimes(1);
      });

      it('does not call mockOriginalStopCallbackMethod', () => {
        expect(mockOriginalStopCallbackMethod).not.toHaveBeenCalled();
      });
    });

    describe('when a stop handler returns undefined', () => {
      let methodReturnValue;
      const stopCallback = jest.fn().mockReturnValue(undefined);

      beforeEach(() => {
        addStopCallback(stopCallback);

        methodReturnValue = mockKeydown();
      });

      it('returns originalMethodReturnValue', () => {
        expect(methodReturnValue).toBe(originalMethodReturnValue);
      });

      it('calls stop callback', () => {
        expect(stopCallback).toHaveBeenCalledTimes(1);
      });

      // Because this is the only registered stop callback, the next callback
      // is the original method.
      it('does call original stopCallback method', () => {
        expect(mockOriginalStopCallbackMethod).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('input focus lock', () => {
    let clearStopCallbacks;
    let suppressShortcutsUntilInputFocus;
    let resetInputFocusLockForTests;

    const runStopCallback = () =>
      Mousetrap.prototype.stopCallback.call({}, { type: 'keydown' }, document.body, 'r');

    beforeEach(async () => {
      ({
        clearStopCallbacksForTests: clearStopCallbacks,
        suppressShortcutsUntilInputFocus,
        resetInputFocusLockForTests,
      } = await import('~/lib/mousetrap'));

      window.gon = { ...window.gon, keyboard_shortcuts_enabled: true };
      clearStopCallbacks();
      resetInputFocusLockForTests();
    });

    describe('when engaged', () => {
      beforeEach(() => {
        suppressShortcutsUntilInputFocus();
      });

      it('causes the Mousetrap stop callback to return true', () => {
        expect(runStopCallback()).toBe(true);
      });

      it('releases after the safety timeout elapses', () => {
        jest.advanceTimersByTime(500);

        expect(runStopCallback()).toBe(originalMethodReturnValue);
      });

      it('extends the timeout when called again', () => {
        jest.advanceTimersByTime(400);
        suppressShortcutsUntilInputFocus();

        jest.advanceTimersByTime(400);
        expect(runStopCallback()).toBe(true);

        jest.advanceTimersByTime(150);
        expect(runStopCallback()).toBe(originalMethodReturnValue);
      });

      it('accepts a custom timeout', () => {
        resetInputFocusLockForTests();
        suppressShortcutsUntilInputFocus({ timeoutMs: 100 });

        jest.advanceTimersByTime(100);
        expect(runStopCallback()).toBe(originalMethodReturnValue);
      });
    });

    describe('when keyboard shortcuts are disabled for the user', () => {
      beforeEach(() => {
        window.gon.keyboard_shortcuts_enabled = false;
      });

      it('does not engage the lock', () => {
        suppressShortcutsUntilInputFocus();

        expect(runStopCallback()).toBe(originalMethodReturnValue);
      });
    });

    describe('when not engaged', () => {
      it('delegates to the original Mousetrap stop callback', () => {
        expect(runStopCallback()).toBe(originalMethodReturnValue);
      });
    });

    describe('focusin release', () => {
      beforeEach(() => {
        suppressShortcutsUntilInputFocus();
      });

      it('releases the lock when an input element receives focus', () => {
        const input = document.createElement('input');
        document.body.appendChild(input);

        input.dispatchEvent(new FocusEvent('focusin', { bubbles: true }));

        expect(runStopCallback()).toBe(originalMethodReturnValue);

        input.remove();
      });

      it('releases the lock when a textarea receives focus', () => {
        const textarea = document.createElement('textarea');
        document.body.appendChild(textarea);

        textarea.dispatchEvent(new FocusEvent('focusin', { bubbles: true }));

        expect(runStopCallback()).toBe(originalMethodReturnValue);

        textarea.remove();
      });

      it('releases the lock when a select element receives focus', () => {
        const select = document.createElement('select');
        document.body.appendChild(select);

        select.dispatchEvent(new FocusEvent('focusin', { bubbles: true }));

        expect(runStopCallback()).toBe(originalMethodReturnValue);

        select.remove();
      });

      it('releases the lock when a contenteditable element receives focus', () => {
        const editable = document.createElement('div');
        editable.setAttribute('contenteditable', 'true');

        Object.defineProperty(editable, 'isContentEditable', { value: true });
        document.body.appendChild(editable);

        editable.dispatchEvent(new FocusEvent('focusin', { bubbles: true }));

        expect(runStopCallback()).toBe(originalMethodReturnValue);

        editable.remove();
      });

      it('does not release the lock when a non-input element receives focus', () => {
        const button = document.createElement('button');
        document.body.appendChild(button);

        button.dispatchEvent(new FocusEvent('focusin', { bubbles: true }));

        expect(runStopCallback()).toBe(true);

        button.remove();
      });
    });
  });
});
