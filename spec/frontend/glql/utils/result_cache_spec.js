import ResultCache from '~/glql/utils/result_cache';

describe('ResultCache', () => {
  let cache;

  beforeEach(() => {
    cache = new ResultCache();
  });

  it('returns nothing for a key it has not seen', () => {
    expect(cache.read('query')).toBeUndefined();
    expect(cache.size).toBe(0);
  });

  it('returns what was set for a key', () => {
    cache.set('query', { nodes: [1] }, 'panel A');

    expect(cache.read('query')).toEqual({ nodes: [1] });
    expect(cache.size).toBe(1);
  });

  it('replaces the data of an existing key', () => {
    cache.set('query', { nodes: [1] }, 'panel A');
    cache.set('query', { nodes: [2] }, 'panel A');

    expect(cache.read('query')).toEqual({ nodes: [2] });
    expect(cache.size).toBe(1);
  });

  it('drops the oldest entry past 200', () => {
    Array.from({ length: 201 }, (_, i) => cache.set(`query ${i}`, { nodes: [i] }));

    expect(cache.size).toBe(200);
    expect(cache.read('query 0')).toBeUndefined();
    expect(cache.read('query 200')).toEqual({ nodes: [200] });
  });

  it('keeps an old entry past 200 while it is still being read', () => {
    Array.from({ length: 200 }, (_, i) => cache.set(`query ${i}`, { nodes: [i] }));
    cache.read('query 0');
    cache.set('query 200', { nodes: [200] });

    expect(cache.read('query 0')).toEqual({ nodes: [0] });
    expect(cache.read('query 1')).toBeUndefined();
  });

  describe('five minutes after an entry was set', () => {
    beforeEach(() => {
      cache.set('query', { nodes: [1] }, 'panel A');
      jest.spyOn(Date, 'now').mockReturnValue(Date.now() + 5 * 60 * 1000);
    });

    it('drops the entry instead of returning it', () => {
      expect(cache.read('query')).toBeUndefined();
      expect(cache.size).toBe(0);
    });

    it('returns an entry set since', () => {
      cache.set('query', { nodes: [2] }, 'panel A');

      expect(cache.read('query')).toEqual({ nodes: [2] });
    });
  });

  it('returns an entry set just under five minutes ago', () => {
    cache.set('query', { nodes: [1] }, 'panel A');
    jest.spyOn(Date, 'now').mockReturnValue(Date.now() + 5 * 60 * 1000 - 1);

    expect(cache.read('query')).toEqual({ nodes: [1] });
  });

  describe('claim', () => {
    it('reads as a miss until data is set', () => {
      cache.claim('query', 'panel A');

      expect(cache.read('query')).toBeUndefined();
      expect(cache.size).toBe(1);
    });

    it('lets a forget of the claiming tag drop the data set afterwards by another', () => {
      cache.claim('query', 'panel B');
      cache.set('query', { nodes: [1] }, 'panel A');
      cache.forget('panel B');

      expect(cache.read('query')).toBeUndefined();
    });

    it('keeps the data of an entry that already exists', () => {
      cache.set('query', { nodes: [1] }, 'panel A');
      cache.claim('query', 'panel B');

      expect(cache.read('query')).toEqual({ nodes: [1] });
      expect(cache.size).toBe(1);
    });

    it('records nothing without a tag', () => {
      cache.claim('query');

      expect(cache.size).toBe(0);
    });

    it('counts against the cap', () => {
      Array.from({ length: 200 }, (_, i) => cache.set(`query ${i}`, { nodes: [i] }));
      cache.claim('query 200', 'panel A');

      expect(cache.size).toBe(200);
      expect(cache.read('query 0')).toBeUndefined();
    });
  });

  describe('delete', () => {
    const data = { nodes: [1] };

    beforeEach(() => {
      cache.set('query', data, 'panel A');
    });

    it('drops the entry holding the data', () => {
      cache.delete('query', data);

      expect(cache.read('query')).toBeUndefined();
    });

    it('keeps an entry that has been replaced since', () => {
      cache.set('query', { nodes: [2] }, 'panel A');
      cache.delete('query', data);

      expect(cache.read('query')).toEqual({ nodes: [2] });
    });
  });

  describe('forget', () => {
    beforeEach(() => {
      cache.set('query A', { nodes: [1] }, 'panel A');
      cache.set('query B', { nodes: [2] }, 'panel B');
    });

    it('drops the entries set under the tag and keeps the others', () => {
      cache.forget('panel A');

      expect(cache.read('query A')).toBeUndefined();
      expect(cache.read('query B')).toEqual({ nodes: [2] });
    });

    it('drops an entry another tag only read', () => {
      cache.read('query A', 'panel B');
      cache.forget('panel B');

      expect(cache.read('query A')).toBeUndefined();
      expect(cache.read('query B')).toBeUndefined();
    });

    it('keeps an entry read without a tag', () => {
      cache.read('query A');
      cache.forget(undefined);

      expect(cache.read('query A')).toEqual({ nodes: [1] });
    });

    it('keeps everything for an unknown tag', () => {
      cache.forget('panel C');

      expect(cache.size).toBe(2);
    });
  });
});
