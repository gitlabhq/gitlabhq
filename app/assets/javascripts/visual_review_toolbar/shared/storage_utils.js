import { setUsingGracefulStorageFlag } from '../store/state';

const TEST_KEY = 'gitlab-storage-test';

const createStorageStub = () => {
  const items = {};

  return {
    getItem(key) {
      return items[key];
    },
    setItem(key, value) {
      items[key] = value;
    },
    removeItem(key) {
      delete items[key];
    },
  };
};

const hasStorageSupport = storage => {
  // Support test taken from https://stackoverflow.com/a/11214467/1708147
  try {
    storage.setItem(TEST_KEY, TEST_KEY);
    storage.removeItem(TEST_KEY);
    setUsingGracefulStorageFlag(true);

    return true;
  } catch (err) {
    setUsingGracefulStorageFlag(false);
    return false;
  }
};

const useGracefulStorage = storage =>
  // If a browser does not support local storage, let's return a graceful implementation.
  hasStorageSupport(storage) ? storage : createStorageStub();

const localStorage = useGracefulStorage(window.localStorage);
const sessionStorage = useGracefulStorage(window.sessionStorage);

export { localStorage, sessionStorage };
