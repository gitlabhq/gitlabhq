import { FaviconOverlayManager } from '@gitlab/favicon-overlay';
import { memoize } from 'lodash';

// FaviconOverlayManager is a glorious singleton/static class. Let's start to encapsulate that with this helper.
const getDefaultFaviconManager = memoize(async () => {
  await FaviconOverlayManager.initialize({ faviconSelector: '#favicon' });

  return FaviconOverlayManager;
});

export const setFaviconOverlay = async (path) => {
  const manager = await getDefaultFaviconManager();

  manager.setFaviconOverlay(path);
};

export const resetFavicon = async () => {
  const manager = await getDefaultFaviconManager();

  manager.resetFaviconOverlay();
};

/**
 * Clears the cached memoization of the default manager.
 *
 * This is needed for determinism in tests.
 */
export const clearMemoizeCache = () => {
  getDefaultFaviconManager.cache.clear();
};
