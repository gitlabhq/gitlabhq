import {
  getStorageValue,
  saveStorageValue,
  removeStorageValue,
  getSessionStorageValue,
  saveSessionStorageValue,
  removeSessionStorageValue,
} from '~/lib/utils/local_storage';

describe('Local Storage Utils', () => {
  const TEST_KEY = 'test_storage_key';
  const STRING_VALUE = 'test string value';
  const OBJECT_VALUE = { name: 'test object', count: 42 };
  const ARRAY_VALUE = [1, 2, 'three', { four: 4 }];
  const NUMBER_VALUE = 123.45;
  let spy;

  beforeEach(() => {
    // Clear localStorage before each test
    localStorage.clear();
    // Spy on console.warn to test warning messages
    spy = jest.spyOn(console, 'warn').mockImplementation(() => {});
  });

  describe('saveStorageValue', () => {
    it('saves string values correctly', () => {
      saveStorageValue(TEST_KEY, STRING_VALUE);
      expect(localStorage.getItem(TEST_KEY)).toBe(JSON.stringify(STRING_VALUE));
    });

    it('saves object values correctly', () => {
      saveStorageValue(TEST_KEY, OBJECT_VALUE);
      expect(localStorage.getItem(TEST_KEY)).toBe(JSON.stringify(OBJECT_VALUE));
    });

    it('saves array values correctly', () => {
      saveStorageValue(TEST_KEY, ARRAY_VALUE);
      expect(localStorage.getItem(TEST_KEY)).toBe(JSON.stringify(ARRAY_VALUE));
    });

    it('saves number values correctly', () => {
      saveStorageValue(TEST_KEY, NUMBER_VALUE);
      expect(localStorage.getItem(TEST_KEY)).toBe(JSON.stringify(NUMBER_VALUE));
    });

    it('saves string values in legacy mode (asString=true)', () => {
      saveStorageValue(TEST_KEY, STRING_VALUE, true);
      expect(localStorage.getItem(TEST_KEY)).toBe(STRING_VALUE);
    });

    it('warns when saving non-string values with asString=true', () => {
      saveStorageValue(TEST_KEY, OBJECT_VALUE, true);
      expect(spy).toHaveBeenCalled();
      expect(localStorage.getItem(TEST_KEY)).toBe('[object Object]');
    });
  });

  describe('getStorageValue', () => {
    it('returns { exists: false } when key does not exist', () => {
      const result = getStorageValue('nonexistent_key');
      expect(result).toEqual({ exists: false });
    });

    it('retrieves string values correctly', () => {
      localStorage.setItem(TEST_KEY, JSON.stringify(STRING_VALUE));
      const result = getStorageValue(TEST_KEY);
      expect(result).toEqual({ exists: true, value: STRING_VALUE });
    });

    it('retrieves object values correctly', () => {
      localStorage.setItem(TEST_KEY, JSON.stringify(OBJECT_VALUE));
      const result = getStorageValue(TEST_KEY);
      expect(result).toEqual({ exists: true, value: OBJECT_VALUE });
    });

    it('retrieves array values correctly', () => {
      localStorage.setItem(TEST_KEY, JSON.stringify(ARRAY_VALUE));
      const result = getStorageValue(TEST_KEY);
      expect(result).toEqual({ exists: true, value: ARRAY_VALUE });
    });

    it('retrieves number values correctly', () => {
      localStorage.setItem(TEST_KEY, JSON.stringify(NUMBER_VALUE));
      const result = getStorageValue(TEST_KEY);
      expect(result).toEqual({ exists: true, value: NUMBER_VALUE });
    });

    it('retrieves string values in legacy mode (asString=true)', () => {
      localStorage.setItem(TEST_KEY, STRING_VALUE);
      const result = getStorageValue(TEST_KEY, true);
      expect(result).toEqual({ exists: true, value: STRING_VALUE });
    });

    it('handles JSON parse errors gracefully', () => {
      localStorage.setItem(TEST_KEY, '{invalid json}');
      const result = getStorageValue(TEST_KEY);
      expect(result).toEqual({ exists: false });
      expect(spy).toHaveBeenCalled();
    });
  });

  describe('removeStorageValue', () => {
    it('removes the specified key from localStorage', () => {
      // Setup
      localStorage.setItem(TEST_KEY, 'some value');
      expect(localStorage.getItem(TEST_KEY)).not.toBeNull();

      // Test
      removeStorageValue(TEST_KEY);

      // Verify
      expect(localStorage.getItem(TEST_KEY)).toBeNull();
    });

    it('does not affect other keys when removing a specific key', () => {
      // Setup
      const OTHER_KEY = 'other_key';
      localStorage.setItem(TEST_KEY, 'test value');
      localStorage.setItem(OTHER_KEY, 'other value');

      // Test
      removeStorageValue(TEST_KEY);

      // Verify
      expect(localStorage.getItem(TEST_KEY)).toBeNull();
      expect(localStorage.getItem(OTHER_KEY)).toBe('other value');
    });
  });

  describe('saveSessionStorageValue', () => {
    beforeEach(() => {
      sessionStorage.clear();
    });

    it('saves string values correctly', () => {
      saveSessionStorageValue(TEST_KEY, STRING_VALUE);
      expect(sessionStorage.getItem(TEST_KEY)).toBe(JSON.stringify(STRING_VALUE));
    });

    it('saves object values correctly', () => {
      saveSessionStorageValue(TEST_KEY, OBJECT_VALUE);
      expect(sessionStorage.getItem(TEST_KEY)).toBe(JSON.stringify(OBJECT_VALUE));
    });

    it('saves array values correctly', () => {
      saveSessionStorageValue(TEST_KEY, ARRAY_VALUE);
      expect(sessionStorage.getItem(TEST_KEY)).toBe(JSON.stringify(ARRAY_VALUE));
    });

    it('saves number values correctly', () => {
      saveSessionStorageValue(TEST_KEY, NUMBER_VALUE);
      expect(sessionStorage.getItem(TEST_KEY)).toBe(JSON.stringify(NUMBER_VALUE));
    });
  });

  describe('getSessionStorageValue', () => {
    beforeEach(() => {
      sessionStorage.clear();
    });

    it('returns { exists: false } when key does not exist', () => {
      const result = getSessionStorageValue('nonexistent_key');
      expect(result).toEqual({ exists: false });
    });

    it('retrieves string values correctly', () => {
      sessionStorage.setItem(TEST_KEY, JSON.stringify(STRING_VALUE));
      const result = getSessionStorageValue(TEST_KEY);
      expect(result).toEqual({ exists: true, value: STRING_VALUE });
    });

    it('retrieves object values correctly', () => {
      sessionStorage.setItem(TEST_KEY, JSON.stringify(OBJECT_VALUE));
      const result = getSessionStorageValue(TEST_KEY);
      expect(result).toEqual({ exists: true, value: OBJECT_VALUE });
    });

    it('retrieves array values correctly', () => {
      sessionStorage.setItem(TEST_KEY, JSON.stringify(ARRAY_VALUE));
      const result = getSessionStorageValue(TEST_KEY);
      expect(result).toEqual({ exists: true, value: ARRAY_VALUE });
    });

    it('retrieves number values correctly', () => {
      sessionStorage.setItem(TEST_KEY, JSON.stringify(NUMBER_VALUE));
      const result = getSessionStorageValue(TEST_KEY);
      expect(result).toEqual({ exists: true, value: NUMBER_VALUE });
    });

    it('handles JSON parse errors gracefully', () => {
      sessionStorage.setItem(TEST_KEY, '{invalid json}');
      const result = getSessionStorageValue(TEST_KEY);
      expect(result).toEqual({ exists: false });
      expect(spy).toHaveBeenCalled();
    });
  });

  describe('removeSessionStorageValue', () => {
    beforeEach(() => {
      sessionStorage.clear();
    });

    it('removes the specified key from sessionStorage', () => {
      sessionStorage.setItem(TEST_KEY, 'some value');
      expect(sessionStorage.getItem(TEST_KEY)).not.toBeNull();

      removeSessionStorageValue(TEST_KEY);

      expect(sessionStorage.getItem(TEST_KEY)).toBeNull();
    });

    it('does not affect other keys when removing a specific key', () => {
      const OTHER_KEY = 'other_key';
      sessionStorage.setItem(TEST_KEY, 'test value');
      sessionStorage.setItem(OTHER_KEY, 'other value');

      removeSessionStorageValue(TEST_KEY);

      expect(sessionStorage.getItem(TEST_KEY)).toBeNull();
      expect(sessionStorage.getItem(OTHER_KEY)).toBe('other value');
    });
  });

  describe('sessionStorage integration tests', () => {
    beforeEach(() => {
      sessionStorage.clear();
    });

    it('can save and retrieve values in a round trip', () => {
      saveSessionStorageValue(TEST_KEY, OBJECT_VALUE);
      const result = getSessionStorageValue(TEST_KEY);
      expect(result.exists).toBe(true);
      expect(result.value).toEqual(OBJECT_VALUE);
    });

    it('can save, remove, and verify non-existence of values', () => {
      saveSessionStorageValue(TEST_KEY, OBJECT_VALUE);
      expect(getSessionStorageValue(TEST_KEY).exists).toBe(true);

      removeSessionStorageValue(TEST_KEY);
      expect(getSessionStorageValue(TEST_KEY).exists).toBe(false);
    });

    it('is isolated from localStorage', () => {
      saveSessionStorageValue(TEST_KEY, OBJECT_VALUE);
      expect(getStorageValue(TEST_KEY).exists).toBe(false);

      saveStorageValue(TEST_KEY, STRING_VALUE);
      expect(getSessionStorageValue(TEST_KEY).value).toEqual(OBJECT_VALUE);
    });
  });

  describe('integration tests', () => {
    it('can save and retrieve values in a round trip', () => {
      saveStorageValue(TEST_KEY, OBJECT_VALUE);
      const result = getStorageValue(TEST_KEY);
      expect(result.exists).toBe(true);
      expect(result.value).toEqual(OBJECT_VALUE);
    });

    it('can save and retrieve string values in legacy mode', () => {
      saveStorageValue(TEST_KEY, STRING_VALUE, true);
      const result = getStorageValue(TEST_KEY, true);
      expect(result.exists).toBe(true);
      expect(result.value).toBe(STRING_VALUE);
    });

    it('can save, remove, and verify non-existence of values', () => {
      saveStorageValue(TEST_KEY, OBJECT_VALUE);
      expect(getStorageValue(TEST_KEY).exists).toBe(true);

      removeStorageValue(TEST_KEY);
      expect(getStorageValue(TEST_KEY).exists).toBe(false);
    });
  });
});
