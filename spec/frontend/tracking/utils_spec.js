import {
  renameKey,
  getReferrersCache,
  addExperimentContext,
  addReferrersCacheEntry,
  filterOldReferrersCacheEntries,
} from '~/tracking/utils';
import { TRACKING_CONTEXT_SCHEMA } from '~/experimentation/constants';
import { REFERRER_TTL, URLS_CACHE_STORAGE_KEY } from '~/tracking/constants';
import { TEST_HOST } from 'helpers/test_constants';

jest.mock('~/experimentation/utils', () => ({
  getExperimentData: jest.fn().mockReturnValue({}),
}));

describe('~/tracking/utils', () => {
  beforeEach(() => {
    window.gl = window.gl || {};
    window.gl.snowplowStandardContext = {};
  });

  describe('addExperimentContext', () => {
    const options = {
      category: 'root:index',
      action: 'generic',
    };

    it('returns same options if no experiment is provided', () => {
      expect(addExperimentContext({ options })).toStrictEqual({ options });
    });

    it('adds experiment if provided', () => {
      const experiment = 'TEST_EXPERIMENT_NAME';

      expect(addExperimentContext({ experiment, ...options })).toStrictEqual({
        ...options,
        context: { data: {}, schema: TRACKING_CONTEXT_SCHEMA },
      });
    });
  });

  describe('renameKey', () => {
    it('renames a given key', () => {
      expect(renameKey({ allow: [] }, 'allow', 'permit')).toStrictEqual({ permit: [] });
    });
  });

  describe('referrers cache', () => {
    describe('filterOldReferrersCacheEntries', () => {
      it('removes entries with old or no timestamp', () => {
        const now = Date.now();
        const cache = [{ timestamp: now }, { timestamp: now - REFERRER_TTL }, { referrer: '' }];

        expect(filterOldReferrersCacheEntries(cache)).toStrictEqual([{ timestamp: now }]);
      });
    });

    describe('getReferrersCache', () => {
      beforeEach(() => {
        localStorage.removeItem(URLS_CACHE_STORAGE_KEY);
      });

      it('returns an empty array if cache is not found', () => {
        expect(getReferrersCache()).toHaveLength(0);
      });

      it('returns an empty array if cache is invalid', () => {
        localStorage.setItem(URLS_CACHE_STORAGE_KEY, 'Invalid JSON');

        expect(getReferrersCache()).toHaveLength(0);
      });

      it('returns parsed entries if valid', () => {
        localStorage.setItem(
          URLS_CACHE_STORAGE_KEY,
          JSON.stringify([{ referrer: '', timestamp: Date.now() }]),
        );

        expect(getReferrersCache()).toHaveLength(1);
      });
    });

    describe('addReferrersCacheEntry', () => {
      it('unshifts entry and adds timestamp', () => {
        const now = Date.now();

        addReferrersCacheEntry([{ referrer: '', originalUrl: TEST_HOST, timestamp: now }], {
          referrer: TEST_HOST,
        });

        const cache = getReferrersCache();

        expect(cache).toHaveLength(2);
        expect(cache[0].referrer).toBe(TEST_HOST);
        expect(cache[0].timestamp).toBeDefined();
      });
    });
  });
});
