/**
 * Manage the instance of a custom `window.localStorage`
 *
 * This only encapsulates the setup / teardown logic so that it can easily be
 * reused with different implementations (i.e. a spy or a fake)
 *
 * @param {() => any} fn Function that returns the object to use for localStorage
 */
const useLocalStorage = (fn) => {
  let originalDescriptor;

  beforeEach(() => {
    originalDescriptor = Object.getOwnPropertyDescriptor(window, 'localStorage');

    const mock = fn();

    Object.defineProperty(window, 'localStorage', {
      ...originalDescriptor,
      get: () => mock,
    });
  });

  afterEach(() => {
    Object.defineProperty(window, 'localStorage', originalDescriptor);
  });
};

/**
 * Create an object with the localStorage interface but `jest.fn()` implementations.
 */
const createLocalStorageSpy = () => {
  let storage = {};

  return {
    get length() {
      return Object.keys(storage).length;
    },
    clear: jest.fn(() => {
      storage = {};
    }),
    getItem: jest.fn((key) => (key in storage ? storage[key] : null)),
    setItem: jest.fn((key, value) => {
      storage[key] = value;
    }),
    removeItem: jest.fn((key) => delete storage[key]),
  };
};

/**
 * Before each test, overwrite `window.localStorage` with a spy implementation.
 */
export const useLocalStorageSpy = () => useLocalStorage(createLocalStorageSpy);
