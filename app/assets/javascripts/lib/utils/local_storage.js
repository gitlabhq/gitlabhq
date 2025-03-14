import { isString } from 'lodash';

/**
 * Serializes a value for storage in localStorage
 * @param {*} val - The value to serialize
 * @param {boolean} asString - Whether to store as raw string (legacy mode)
 * @returns {string} The serialized value
 */
const serializeValue = (val, asString = false) => {
  if (!isString(val) && asString) {
    // eslint-disable-next-line no-console
    console.warn(
      `[gitlab] LocalStorageSync is saving`,
      val,
      `but it is not a string and the 'asString' param is true. This will save and restore the stringified value rather than the original value.`,
    );
  }

  return asString ? val : JSON.stringify(val);
};

/**
 * Deserializes a value from localStorage
 * @param {string} val - The stored string value
 * @param {boolean} asString - Whether the value was stored as raw string (legacy mode)
 * @returns {*} The deserialized value
 */
const deserializeValue = (val, asString = false) => {
  return asString ? val : JSON.parse(val);
};

/**
 * Gets a value from localStorage with proper deserialization
 * @param {string} storageKey - The localStorage key
 * @param {boolean} asString - Whether to treat as raw string (legacy mode)
 * @returns {Object} Object with exists flag and value if it exists
 */
export const getStorageValue = (storageKey, asString = false) => {
  const value = localStorage.getItem(storageKey);

  if (value === null) {
    return { exists: false };
  }

  try {
    return { exists: true, value: deserializeValue(value, asString) };
  } catch {
    // eslint-disable-next-line no-console
    console.warn(
      `[gitlab] Failed to deserialize value from localStorage (key=${storageKey})`,
      value,
    );
    // default to "don't use localStorage value"
    return { exists: false };
  }
};

/**
 * Saves a value to localStorage with proper serialization
 * @param {string} storageKey - The localStorage key
 * @param {*} val - The value to store
 * @param {boolean} asString - Whether to store as raw string (legacy mode)
 */
export const saveStorageValue = (storageKey, val, asString = false) => {
  localStorage.setItem(storageKey, serializeValue(val, asString));
};

/**
 * Removes a value from localStorage
 * @param {string} storageKey - The localStorage key to remove
 */
export const removeStorageValue = (storageKey) => {
  localStorage.removeItem(storageKey);
};
