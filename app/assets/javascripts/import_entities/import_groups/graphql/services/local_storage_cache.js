import { debounce, merge } from 'lodash';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

const OLD_KEY = 'gl-bulk-imports-import-state-v2';
export const KEY = 'gl-bulk-imports-import-state-v3';
export const DEBOUNCE_INTERVAL = DEFAULT_DEBOUNCE_AND_THROTTLE_MS;

export class LocalStorageCache {
  constructor({ storage = window.localStorage } = {}) {
    this.storage = storage;
    this.cache = this.loadCacheFromStorage();
    try {
      // remove old storage data
      this.storage.removeItem(OLD_KEY);
    } catch {
      // empty catch intended
    }

    // cache for searching data by jobid
    this.jobsLookupCache = {};
  }

  loadCacheFromStorage() {
    try {
      const storage = JSON.parse(this.storage.getItem(KEY)) ?? {};
      Object.values(storage).forEach((entry) => {
        if (entry.progress && !('message' in entry.progress)) {
          // eslint-disable-next-line no-param-reassign
          entry.progress.message = '';
        }
      });
      return storage;
    } catch {
      return {};
    }
  }

  set(webUrl, data) {
    this.cache[webUrl] = data;
    this.saveCacheToStorage();
    // There are changes to jobIds, drop cache
    this.jobsLookupCache = {};
  }

  get(webUrl) {
    return this.cache[webUrl];
  }

  getCacheKeysByJobId(jobId) {
    // this is invoked by polling, so we would like to cache results
    if (!this.jobsLookupCache[jobId]) {
      this.jobsLookupCache[jobId] = Object.keys(this.cache).filter(
        (url) => this.cache[url]?.progress.id === jobId,
      );
    }

    return this.jobsLookupCache[jobId];
  }

  updateStatusByJobId(jobId, status, hasFailures) {
    this.getCacheKeysByJobId(jobId).forEach((webUrl) =>
      this.set(webUrl, {
        ...this.get(webUrl),
        progress: {
          id: jobId,
          status,
          hasFailures,
        },
      }),
    );
    this.saveCacheToStorage();
  }

  saveCacheToStorage = debounce(() => {
    try {
      // storage might be changed in other tab so fetch first
      this.storage.setItem(KEY, JSON.stringify(merge({}, this.loadCacheFromStorage(), this.cache)));
    } catch {
      // empty catch intentional: storage might be unavailable or full
    }
  }, DEBOUNCE_INTERVAL);
}
