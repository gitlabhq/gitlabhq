import { createDebouncedVisibilityHandler } from '~/homepage/utils/debounced_visibility_handler';

describe('debouncedVisibilityHandler', () => {
  let mockReloadFunction;
  let handler;

  beforeEach(() => {
    mockReloadFunction = jest.fn();

    // Mock Date.now with a specific starting time
    jest.spyOn(Date, 'now').mockReturnValue(1000);

    // Mock document.hidden property
    Object.defineProperty(document, 'hidden', {
      writable: true,
      value: false,
    });
  });

  afterEach(() => {
    Date.now.mockRestore();
  });

  describe('createDebouncedVisibilityHandler', () => {
    describe('basic functionality', () => {
      it('does not call reload function on first visibility change when document is visible', () => {
        handler = createDebouncedVisibilityHandler(mockReloadFunction, 5000);

        handler();

        expect(mockReloadFunction).not.toHaveBeenCalled();
      });

      it('does not call reload function when document is hidden', () => {
        document.hidden = true;
        handler = createDebouncedVisibilityHandler(mockReloadFunction, 5000);

        handler();

        expect(mockReloadFunction).not.toHaveBeenCalled();
      });

      it('accepts a custom reload function but does not call it on first visibility change', () => {
        const customReload = jest.fn();

        handler = createDebouncedVisibilityHandler(customReload, 1000);
        handler();

        expect(customReload).not.toHaveBeenCalled();
      });
    });

    describe('debouncing behavior', () => {
      it('debounces repeated calls within the debounce time window', () => {
        handler = createDebouncedVisibilityHandler(mockReloadFunction, 5000);

        // First call at time 1000 - should not reload (just sets timestamp)
        handler();
        expect(mockReloadFunction).not.toHaveBeenCalled();

        // Immediate second call at same time - should be ignored (within debounce window)
        handler();
        expect(mockReloadFunction).not.toHaveBeenCalled();

        // Call after 3 seconds (time 4000) - still within 5000ms window, should be ignored
        Date.now.mockReturnValue(4000);
        handler();
        expect(mockReloadFunction).not.toHaveBeenCalled();

        // Call after 4.9 seconds (time 5900) - still within 5000ms window, should be ignored
        Date.now.mockReturnValue(5900);
        handler();
        expect(mockReloadFunction).not.toHaveBeenCalled();
      });

      it('allows reload after debounce time has passed', () => {
        handler = createDebouncedVisibilityHandler(mockReloadFunction, 5000);

        // First call at time 1000 - sets timestamp but doesn't reload
        handler();
        expect(mockReloadFunction).not.toHaveBeenCalled();

        // Call exactly 5 seconds later (time 6000) - should work now
        Date.now.mockReturnValue(6000);
        handler();
        expect(mockReloadFunction).toHaveBeenCalledTimes(1);

        // Call 1ms after that (time 6001) - should be debounced again
        Date.now.mockReturnValue(6001);
        handler();
        expect(mockReloadFunction).toHaveBeenCalledTimes(1);

        // Call 5 seconds after the reload (time 11000) - should work
        Date.now.mockReturnValue(11000);
        handler();
        expect(mockReloadFunction).toHaveBeenCalledTimes(2);
      });

      it('works with custom debounce times', () => {
        // Test with 1 second debounce
        handler = createDebouncedVisibilityHandler(mockReloadFunction, 1000);

        // First call - sets timestamp but doesn't reload
        handler();
        expect(mockReloadFunction).not.toHaveBeenCalled();

        // Within 1 second - should be debounced
        Date.now.mockReturnValue(1500);
        handler();
        expect(mockReloadFunction).not.toHaveBeenCalled();

        // After 1 second - should work
        Date.now.mockReturnValue(2000);
        handler();
        expect(mockReloadFunction).toHaveBeenCalledTimes(1);
      });

      it('works with very short debounce times', () => {
        // Test with 100ms debounce
        handler = createDebouncedVisibilityHandler(mockReloadFunction, 100);

        // First call - sets timestamp but doesn't reload
        handler();
        expect(mockReloadFunction).not.toHaveBeenCalled();

        // Within 100ms - should be debounced
        Date.now.mockReturnValue(1050);
        handler();
        expect(mockReloadFunction).not.toHaveBeenCalled();

        // After 100ms - should work
        Date.now.mockReturnValue(1100);
        handler();
        expect(mockReloadFunction).toHaveBeenCalledTimes(1);
      });

      it('works with zero debounce time (always allows reload after first call)', () => {
        handler = createDebouncedVisibilityHandler(mockReloadFunction, 0);

        // First call - sets timestamp but doesn't reload
        handler();
        expect(mockReloadFunction).not.toHaveBeenCalled();

        // With 0 debounce, subsequent calls should always work
        handler();
        expect(mockReloadFunction).toHaveBeenCalledTimes(1);

        handler();
        expect(mockReloadFunction).toHaveBeenCalledTimes(2);
      });
    });

    describe('multiple handler instances', () => {
      it('tracks debounce time separately for different handler instances', () => {
        const reload1 = jest.fn();
        const reload2 = jest.fn();

        const handler1 = createDebouncedVisibilityHandler(reload1, 5000);
        const handler2 = createDebouncedVisibilityHandler(reload2, 5000);

        // Both should set timestamp but not reload on first call
        handler1();
        handler2();
        expect(reload1).not.toHaveBeenCalled();
        expect(reload2).not.toHaveBeenCalled();

        // Both should be debounced on immediate second call
        handler1();
        handler2();
        expect(reload1).not.toHaveBeenCalled();
        expect(reload2).not.toHaveBeenCalled();

        // After debounce time, both should work
        Date.now.mockReturnValue(6000);
        handler1();
        handler2();
        expect(reload1).toHaveBeenCalledTimes(1);
        expect(reload2).toHaveBeenCalledTimes(1);
      });

      it('does not interfere between different handler instances with different debounce times', () => {
        const reload1 = jest.fn();
        const reload2 = jest.fn();

        const handler1 = createDebouncedVisibilityHandler(reload1, 5000);
        const handler2 = createDebouncedVisibilityHandler(reload2, 1000);

        // First calls - both set timestamp but don't reload
        handler1();
        handler2();
        expect(reload1).not.toHaveBeenCalled();
        expect(reload2).not.toHaveBeenCalled();

        // After 1.5 seconds - handler2 should work, handler1 should not
        Date.now.mockReturnValue(2500);
        handler1();
        handler2();
        expect(reload1).not.toHaveBeenCalled(); // Still debounced (needs 5s)
        expect(reload2).toHaveBeenCalledTimes(1); // Works (only needs 1s)
      });
    });

    describe('edge cases and error handling', () => {
      it('handles document.hidden changing during execution', () => {
        handler = createDebouncedVisibilityHandler(mockReloadFunction, 5000);

        // Start visible - first call sets timestamp but doesn't reload
        document.hidden = false;
        handler();
        expect(mockReloadFunction).not.toHaveBeenCalled();

        // Change to hidden
        document.hidden = true;
        handler();
        expect(mockReloadFunction).not.toHaveBeenCalled(); // Should not increment

        // Back to visible after debounce time
        document.hidden = false;
        Date.now.mockReturnValue(6000);
        handler();
        expect(mockReloadFunction).toHaveBeenCalledTimes(1);
      });

      it('handles reload function throwing an error', () => {
        const errorThrowingReload = jest.fn(() => {
          throw new Error('Reload failed');
        });

        handler = createDebouncedVisibilityHandler(errorThrowingReload, 5000);

        // First call should not throw (doesn't call reload function)
        expect(() => handler()).not.toThrow();
        expect(errorThrowingReload).not.toHaveBeenCalled();

        // Time tracking should still work - after debounce time, should throw
        Date.now.mockReturnValue(6000);
        expect(() => handler()).toThrow('Reload failed');
        expect(errorThrowingReload).toHaveBeenCalledTimes(1);
      });

      it('uses default debounce time when no time is provided', () => {
        handler = createDebouncedVisibilityHandler(mockReloadFunction);

        // First call - sets timestamp but doesn't reload
        handler();
        expect(mockReloadFunction).not.toHaveBeenCalled();

        // Should use default 5000ms - within window, no reload
        Date.now.mockReturnValue(4999);
        handler();
        expect(mockReloadFunction).not.toHaveBeenCalled();

        // After default 5000ms - should reload
        Date.now.mockReturnValue(6000);
        handler();
        expect(mockReloadFunction).toHaveBeenCalledTimes(1);
      });

      it('handles very large timestamps', () => {
        const largeTimestamp = 2147483647000; // Max 32-bit signed int * 1000
        Date.now.mockReturnValue(largeTimestamp);

        handler = createDebouncedVisibilityHandler(mockReloadFunction, 5000);

        // First call - sets timestamp but doesn't reload
        handler();
        expect(mockReloadFunction).not.toHaveBeenCalled();

        // After debounce time - should reload
        Date.now.mockReturnValue(largeTimestamp + 5000);
        handler();
        expect(mockReloadFunction).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('performance considerations', () => {
    it('maintains performance with rapid successive calls', () => {
      handler = createDebouncedVisibilityHandler(mockReloadFunction, 1000);

      // Make many rapid calls
      for (let i = 0; i < 1000; i += 1) {
        handler();
      }

      // Should not call reload at all (first call sets timestamp, rest are debounced)
      expect(mockReloadFunction).not.toHaveBeenCalled();

      // After debounce time, should work
      Date.now.mockReturnValue(2000);
      handler();
      expect(mockReloadFunction).toHaveBeenCalledTimes(1);
    });

    it('creates independent handlers that do not interfere with each other', () => {
      const handlers = [];
      const reloadFunctions = [];

      // Create many handler instances
      for (let i = 0; i < 100; i += 1) {
        const reloadFn = jest.fn();
        const handlerInstance = createDebouncedVisibilityHandler(reloadFn, 1000);
        reloadFunctions.push(reloadFn);
        handlers.push(handlerInstance);
      }

      // Use all handlers - first calls should not reload
      handlers.forEach((h) => h());

      // Each reload function should not have been called (first call sets timestamp)
      reloadFunctions.forEach((reloadFn) => {
        expect(reloadFn).not.toHaveBeenCalled();
      });

      // This test mainly ensures no errors are thrown with many instances
      expect(handlers).toHaveLength(100);
      expect(reloadFunctions).toHaveLength(100);
    });
  });
});
