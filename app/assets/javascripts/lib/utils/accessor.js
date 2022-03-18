function canAccessProperty(base, property) {
  let safe;

  try {
    safe = Boolean(base[property]);
  } catch (error) {
    safe = false;
  }

  return safe;
}

function canCallFunction(base, functionName, ...args) {
  let safe = true;

  try {
    base[functionName](...args);
  } catch (error) {
    safe = false;
  }

  return safe;
}

/**
 * Determines if `window.localStorage` is available and
 * can be written to and read from.
 *
 * Important: This is not a guarantee that
 * `localStorage.setItem` will work in all cases.
 *
 * `setItem` can still throw exceptions and should be
 * surrounded with a try/catch where used.
 *
 * See: https://developer.mozilla.org/en-US/docs/Web/API/Storage/setItem#exceptions
 */
function canUseLocalStorage() {
  let safe;

  const TEST_KEY = 'canUseLocalStorage';
  const TEST_VALUE = 'true';

  safe = canAccessProperty(window, 'localStorage');
  if (!safe) return safe;

  safe = canCallFunction(window.localStorage, 'setItem', TEST_KEY, TEST_VALUE);

  if (safe) window.localStorage.removeItem(TEST_KEY);

  return safe;
}

/**
 * Determines if `window.crypto` is available.
 */
function canUseCrypto() {
  return window.crypto?.subtle !== undefined;
}

const AccessorUtilities = {
  canUseLocalStorage,
  canUseCrypto,
};

export default AccessorUtilities;
