/**
 * Manage the instance of a custom `window.localStorage`
 *
 * This only encapsulates the setup / teardown logic so that it can easily be
 * reused with different implementations (i.e. a spy or a [fake][1])
 *
 * [1]: https://stackoverflow.com/a/41434763/1708147
 *
 * @param {() => any} fn Function that returns the object to use for localStorage
 */
const useLocalStorage = (fn) => {
  const origLocalStorage = window.localStorage;
  let currentLocalStorage = origLocalStorage;

  Object.defineProperty(window, 'localStorage', {
    get: () => currentLocalStorage,
  });

  beforeEach(() => {
    currentLocalStorage = fn();
  });

  afterEach(() => {
    currentLocalStorage = origLocalStorage;
  });
};

/**
 * Create an object with the localStorage interface but `jest.fn()` implementations.
 */
export const createLocalStorageSpy = () => {
  let storage = {};

  return {
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
