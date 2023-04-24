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
});
