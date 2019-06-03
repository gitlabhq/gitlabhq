function isPropertyAccessSafe(base, property) {
  let safe;

  try {
    safe = Boolean(base[property]);
  } catch (error) {
    safe = false;
  }

  return safe;
}

function isFunctionCallSafe(base, functionName, ...args) {
  let safe = true;

  try {
    base[functionName](...args);
  } catch (error) {
    safe = false;
  }

  return safe;
}

function isLocalStorageAccessSafe() {
  let safe;

  const TEST_KEY = 'isLocalStorageAccessSafe';
  const TEST_VALUE = 'true';

  safe = isPropertyAccessSafe(window, 'localStorage');
  if (!safe) return safe;

  safe = isFunctionCallSafe(window.localStorage, 'setItem', TEST_KEY, TEST_VALUE);

  if (safe) window.localStorage.removeItem(TEST_KEY);

  return safe;
}

const AccessorUtilities = {
  isPropertyAccessSafe,
  isFunctionCallSafe,
  isLocalStorageAccessSafe,
};

export default AccessorUtilities;
