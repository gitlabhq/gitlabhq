import AccessorUtilities from '~/lib/utils/accessor';
import { getStorageValue, saveStorageValue } from '~/lib/utils/local_storage';

export const FREQUENT_COMMANDS_STORAGE_KEY = 'gl.frequent_quick_actions';
const FREQUENT_COMMANDS_LIMIT = 20;
const FREQUENT_PREFIX_LIMIT = 5;
let lastIncrementKey = null;
let lastIncrementFrame = 0;

// Command names are validated at call sites by checking against available items
export const sortCommandsAlphaSafe = (items) => {
  const getComparableName = (item) => (typeof item?.name === 'string' ? item.name.trim() : '');
  const sorted = [...items].sort((a, b) => {
    const aName = getComparableName(a);
    const bName = getComparableName(b);
    const aHas = aName.length > 0;
    const bHas = bName.length > 0;

    if (aHas && bHas) {
      return aName.localeCompare(bName, undefined, { sensitivity: 'base' });
    }
    if (aHas && !bHas) {
      return -1;
    }
    if (!aHas && bHas) {
      return 1;
    }
    return 0;
  });
  return sorted;
};

// Internal: read store as a map of name => count. Migrates legacy arrays.
const readFrequentStore = () => {
  try {
    if (!AccessorUtilities.canUseLocalStorage()) return {};
    const { exists, value } = getStorageValue(FREQUENT_COMMANDS_STORAGE_KEY);
    if (!exists) return {};

    // Legacy: array of strings
    if (Array.isArray(value)) {
      const map = {};
      value.forEach((s) => {
        if (typeof s === 'string' && s.startsWith('/')) {
          map[s] = (map[s] || 0) + 1;
        }
      });
      // Persist migrated format
      try {
        saveStorageValue(FREQUENT_COMMANDS_STORAGE_KEY, map);
      } catch {
        // ignore
      }
      return map;
    }

    // Expected: object map
    if (value && typeof value === 'object') {
      return Object.keys(value).reduce((acc, key) => {
        const k = typeof key === 'string' && key.startsWith('/') ? key : null;
        const count = Number(value[key]);
        if (k && Number.isFinite(count) && count > 0) acc[k] = count;
        return acc;
      }, {});
    }

    return {};
  } catch {
    return {};
  }
};

const saveFrequentStore = (store) => {
  try {
    if (!AccessorUtilities.canUseLocalStorage()) return;
    saveStorageValue(FREQUENT_COMMANDS_STORAGE_KEY, store);
  } catch {
    // ignore
  }
};

export const recordFrequentCommandUsage = (commandName) => {
  try {
    if (!AccessorUtilities.canUseLocalStorage()) return;
    if (typeof commandName !== 'string' || commandName.length === 0) return;
    const normalized = commandName.startsWith('/') ? commandName : `/${commandName}`;
    // Prevent double-count in same animation frame
    const now =
      typeof window !== 'undefined' && window.performance ? window.performance.now() : Date.now();
    const frameBucket = Math.floor(now / 16); // ~60fps frame bucket
    const guardKey = `${normalized}|${frameBucket}`;
    if (lastIncrementKey === guardKey && lastIncrementFrame === frameBucket) return;
    lastIncrementKey = guardKey;
    lastIncrementFrame = frameBucket;
    const store = readFrequentStore();
    store[normalized] = (store[normalized] || 0) + 1;
    // Trim to limit by dropping lowest counts if too large
    const entries = Object.entries(store)
      .sort(([, a], [, b]) => b - a)
      .slice(0, FREQUENT_COMMANDS_LIMIT);
    const trimmed = entries.reduce((acc, [k, v]) => ({ ...acc, [k]: v }), {});
    saveFrequentStore(trimmed);
  } catch {
    // ignore storage errors
  }
};

export const prioritizeCommandsWithFrequent = (items) => {
  const byName = new Map();
  items.forEach((it) => {
    if (typeof it?.name === 'string') byName.set(`/${it.name}`, it);
  });

  const store = readFrequentStore();
  const frequentSorted = Object.entries(store)
    .filter(([name]) => byName.has(name))
    .sort(([, a], [, b]) => b - a)
    .slice(0, FREQUENT_PREFIX_LIMIT)
    .map(([name]) => byName.get(name));

  const seen = new Set(frequentSorted);
  const remaining = sortCommandsAlphaSafe(items.filter((it) => !seen.has(it)));
  return [...frequentSorted, ...remaining];
};
