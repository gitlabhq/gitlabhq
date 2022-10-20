import $ from 'jquery';
import { assignIn } from 'lodash';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';
import SmartInterval from '~/smart_interval';

let interval;

describe('SmartInterval', () => {
  const DEFAULT_MAX_INTERVAL = 100;
  const DEFAULT_STARTING_INTERVAL = 5;
  const DEFAULT_INCREMENT_FACTOR = 2;

  function createDefaultSmartInterval(config) {
    const defaultParams = {
      callback: () => Promise.resolve(),
      startingInterval: DEFAULT_STARTING_INTERVAL,
      maxInterval: DEFAULT_MAX_INTERVAL,
      incrementByFactorOf: DEFAULT_INCREMENT_FACTOR,
      lazyStart: false,
      immediateExecution: false,
      hiddenInterval: null,
    };

    if (config) {
      assignIn(defaultParams, config);
    }

    return new SmartInterval(defaultParams);
  }

  afterEach(() => {
    interval.destroy();
  });

  describe('Increment Interval', () => {
    it('should increment the interval delay', () => {
      interval = createDefaultSmartInterval();

      jest.runOnlyPendingTimers();

      return waitForPromises().then(() => {
        const intervalConfig = interval.cfg;
        const iterationCount = 4;
        const maxIntervalAfterIterations =
          intervalConfig.startingInterval * intervalConfig.incrementByFactorOf ** iterationCount;
        const currentInterval = interval.getCurrentInterval();

        // Provide some flexibility for performance of testing environment
        expect(currentInterval).toBeGreaterThan(intervalConfig.startingInterval);
        expect(currentInterval).toBeLessThanOrEqual(maxIntervalAfterIterations);
      });
    });

    it('should not increment past maxInterval', () => {
      interval = createDefaultSmartInterval({ maxInterval: DEFAULT_STARTING_INTERVAL });

      jest.runOnlyPendingTimers();

      return waitForPromises().then(() => {
        const currentInterval = interval.getCurrentInterval();

        expect(currentInterval).toBe(interval.cfg.maxInterval);
      });
    });

    it('does not increment while waiting for callback', () => {
      interval = createDefaultSmartInterval({
        callback: () => new Promise($.noop),
      });

      jest.runOnlyPendingTimers();

      return waitForPromises().then(() => {
        const oneInterval = interval.cfg.startingInterval * DEFAULT_INCREMENT_FACTOR;

        expect(interval.getCurrentInterval()).toEqual(oneInterval);
      });
    });
  });

  describe('Public methods', () => {
    beforeEach(() => {
      interval = createDefaultSmartInterval();
    });

    it('should cancel an interval', () => {
      jest.runOnlyPendingTimers();

      interval.cancel();

      return waitForPromises().then(() => {
        const { intervalId } = interval.state;
        const currentInterval = interval.getCurrentInterval();
        const intervalLowerLimit = interval.cfg.startingInterval;

        expect(intervalId).toBeUndefined();
        expect(currentInterval).toBe(intervalLowerLimit);
      });
    });

    it('should resume an interval', () => {
      jest.runOnlyPendingTimers();

      interval.cancel();

      interval.resume();

      return waitForPromises().then(() => {
        const { intervalId } = interval.state;

        expect(intervalId).not.toBeUndefined();
      });
    });
  });

  describe('DOM Events', () => {
    beforeEach(() => {
      // This ensures DOM and DOM events are initialized for these specs.
      setHTMLFixture('<div></div>');

      interval = createDefaultSmartInterval();
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('should pause when page is not visible', () => {
      jest.runOnlyPendingTimers();

      return waitForPromises().then(() => {
        expect(interval.state.intervalId).not.toBeUndefined();

        // simulates triggering of visibilitychange event
        interval.onVisibilityChange({ target: { visibilityState: 'hidden' } });

        expect(interval.state.intervalId).toBeUndefined();
      });
    });

    it('should change to the hidden interval when page is not visible', () => {
      interval.destroy();

      const HIDDEN_INTERVAL = 1500;
      interval = createDefaultSmartInterval({ hiddenInterval: HIDDEN_INTERVAL });

      jest.runOnlyPendingTimers();

      return waitForPromises().then(() => {
        expect(interval.state.intervalId).not.toBeUndefined();
        expect(
          interval.getCurrentInterval() >= DEFAULT_STARTING_INTERVAL &&
            interval.getCurrentInterval() <= DEFAULT_MAX_INTERVAL,
        ).toBe(true);

        // simulates triggering of visibilitychange event
        interval.onVisibilityChange({ target: { visibilityState: 'hidden' } });

        expect(interval.state.intervalId).not.toBeUndefined();
        expect(interval.getCurrentInterval()).toBe(HIDDEN_INTERVAL);
      });
    });

    it('should resume when page is becomes visible at the previous interval', () => {
      jest.runOnlyPendingTimers();

      return waitForPromises().then(() => {
        expect(interval.state.intervalId).not.toBeUndefined();

        // simulates triggering of visibilitychange event
        interval.onVisibilityChange({ target: { visibilityState: 'hidden' } });

        expect(interval.state.intervalId).toBeUndefined();

        // simulates triggering of visibilitychange event
        interval.onVisibilityChange({ target: { visibilityState: 'visible' } });

        expect(interval.state.intervalId).not.toBeUndefined();
      });
    });

    it('should cancel on page unload', () => {
      jest.runOnlyPendingTimers();

      return waitForPromises().then(() => {
        $(document).triggerHandler('beforeunload');

        expect(interval.state.intervalId).toBeUndefined();
        expect(interval.getCurrentInterval()).toBe(interval.cfg.startingInterval);
      });
    });

    it('should execute callback before first interval', () => {
      interval = createDefaultSmartInterval({ immediateExecution: true });

      expect(interval.cfg.immediateExecution).toBe(false);
    });
  });
});
