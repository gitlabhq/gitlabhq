/* eslint-disable class-methods-use-this, max-classes-per-file */
import { isMatch } from 'lodash';

/**
 * This class gives us a JSDom friendly DOM observer which we can manually trigger in tests
 *
 * Use this in place of MutationObserver or IntersectionObserver
 */
class MockObserver {
  constructor(cb) {
    this.$_cb = cb;
    this.$_observers = [];
  }

  observe(node, options = {}) {
    this.$_observers.push([node, options]);
  }

  disconnect() {
    this.$_observers = [];
  }

  takeRecords() {}

  // eslint-disable-next-line babel/camelcase
  $_triggerObserve(node, { entry = {}, options = {} } = {}) {
    if (this.$_hasObserver(node, options)) {
      this.$_cb([{ target: node, ...entry }]);
    }
  }

  // eslint-disable-next-line babel/camelcase
  $_hasObserver(node, options = {}) {
    return this.$_observers.some(
      ([obvNode, obvOptions]) => node === obvNode && isMatch(options, obvOptions),
    );
  }
}

class MockIntersectionObserver extends MockObserver {
  unobserve(node) {
    this.$_observers = this.$_observers.filter(([obvNode]) => node === obvNode);
  }
}

/**
 * Use this function to setup a mock observer instance in place of the given DOM Observer
 *
 * Example:
 * ```
 * describe('', () => {
 *   const { trigger: triggerMutate } = useMockMutationObserver();
 *
 *   it('test', () => {
 *     trigger(el, { options: { childList: true }, entry: { } });
 *   });
 * })
 * ```
 *
 * @param {String} key
 */
const useMockObserver = (key, createMock) => {
  let mockObserver;
  let origObserver;

  beforeEach(() => {
    origObserver = global[key];
    global[key] = jest.fn().mockImplementation((...args) => {
      mockObserver = createMock(...args);
      return mockObserver;
    });
  });

  afterEach(() => {
    mockObserver = null;
    global[key] = origObserver;
  });

  const trigger = (...args) => {
    if (!mockObserver) {
      return;
    }

    mockObserver.$_triggerObserve(...args);
  };

  const observersCount = () => mockObserver.$_observers.length;

  return { trigger, observersCount };
};

export const useMockIntersectionObserver = () =>
  useMockObserver('IntersectionObserver', (...args) => new MockIntersectionObserver(...args));

export const useMockMutationObserver = () =>
  useMockObserver('MutationObserver', (...args) => new MockObserver(...args));
