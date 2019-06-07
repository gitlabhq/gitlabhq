import Cache from '~/lib/utils/cache';

describe('Cache', () => {
  const dummyKey = 'just some key';
  const dummyValue = 'more than a value';
  let cache;

  beforeEach(() => {
    cache = new Cache();
  });

  describe('get', () => {
    it('return cached data', () => {
      cache.internalStorage[dummyKey] = dummyValue;

      expect(cache.get(dummyKey)).toBe(dummyValue);
    });

    it('returns undefined for missing data', () => {
      expect(cache.internalStorage[dummyKey]).toBe(undefined);
      expect(cache.get(dummyKey)).toBe(undefined);
    });
  });

  describe('hasData', () => {
    it('return true for cached data', () => {
      cache.internalStorage[dummyKey] = dummyValue;

      expect(cache.hasData(dummyKey)).toBe(true);
    });

    it('returns false for missing data', () => {
      expect(cache.internalStorage[dummyKey]).toBe(undefined);
      expect(cache.hasData(dummyKey)).toBe(false);
    });
  });

  describe('remove', () => {
    it('removes data from cache', () => {
      cache.internalStorage[dummyKey] = dummyValue;

      cache.remove(dummyKey);

      expect(cache.internalStorage[dummyKey]).toBe(undefined);
    });

    it('does nothing for missing data', () => {
      expect(cache.internalStorage[dummyKey]).toBe(undefined);

      cache.remove(dummyKey);

      expect(cache.internalStorage[dummyKey]).toBe(undefined);
    });

    it('does not remove wrong data', () => {
      cache.internalStorage[dummyKey] = dummyValue;
      cache.internalStorage[dummyKey + dummyKey] = dummyValue + dummyValue;

      cache.remove(dummyKey);

      expect(cache.internalStorage[dummyKey]).toBe(undefined);
      expect(cache.internalStorage[dummyKey + dummyKey]).toBe(dummyValue + dummyValue);
    });
  });
});
