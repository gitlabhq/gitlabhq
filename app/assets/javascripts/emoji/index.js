import fuzzaldrinPlus from 'fuzzaldrin-plus';
import emojiAliases from 'emojis/aliases.json';
import axios from '../lib/utils/axios_utils';
import AccessorUtilities from '../lib/utils/accessor';

let emojiMap = null;
let validEmojiNames = null;

export const EMOJI_VERSION = '1';

const isLocalStorageAvailable = AccessorUtilities.isLocalStorageAccessSafe();

async function loadEmoji() {
  if (
    isLocalStorageAvailable &&
    window.localStorage.getItem('gl-emoji-map-version') === EMOJI_VERSION &&
    window.localStorage.getItem('gl-emoji-map')
  ) {
    return JSON.parse(window.localStorage.getItem('gl-emoji-map'));
  }

  // We load the JSON file direct from the server
  // because it can't be loaded from a CDN due to
  // cross domain problems with JSON
  const { data } = await axios.get(
    `${gon.relative_url_root || ''}/-/emojis/${EMOJI_VERSION}/emojis.json`,
  );
  window.localStorage.setItem('gl-emoji-map-version', EMOJI_VERSION);
  window.localStorage.setItem('gl-emoji-map', JSON.stringify(data));
  return data;
}

async function prepareEmojiMap() {
  emojiMap = await loadEmoji();

  validEmojiNames = [...Object.keys(emojiMap), ...Object.keys(emojiAliases)];

  Object.keys(emojiMap).forEach(name => {
    emojiMap[name].aliases = [];
    emojiMap[name].name = name;
  });
  Object.entries(emojiAliases).forEach(([alias, name]) => {
    // This check, `if (name in emojiMap)` is necessary during testing. In
    // production, it shouldn't be necessary, because at no point should there
    // be an entry in aliases.json with no corresponding entry in emojis.json.
    // However, during testing, the endpoint for emojis.json is mocked with a
    // small dataset, whereas aliases.json is always `import`ed directly.
    if (name in emojiMap) emojiMap[name].aliases.push(alias);
  });
}

export function initEmojiMap() {
  initEmojiMap.promise = initEmojiMap.promise || prepareEmojiMap();
  return initEmojiMap.promise;
}

export function normalizeEmojiName(name) {
  return Object.prototype.hasOwnProperty.call(emojiAliases, name) ? emojiAliases[name] : name;
}

export function getValidEmojiNames() {
  return validEmojiNames;
}

export function isEmojiNameValid(name) {
  return validEmojiNames.indexOf(name) >= 0;
}

export function getAllEmoji() {
  return emojiMap;
}

/**
 * Retrieves an emoji by name or alias.
 *
 * Note: `initEmojiMap` must have been called and completed before this method
 * can safely be called.
 *
 * @param {String} query The emoji name
 * @param {Boolean} fallback If true, a fallback emoji will be returned if the
 * named emoji does not exist. Defaults to false.
 * @returns {Object} The matching emoji.
 */
export function getEmoji(query, fallback = false) {
  // TODO https://gitlab.com/gitlab-org/gitlab/-/issues/268208
  const fallbackEmoji = emojiMap.grey_question;
  if (!query) {
    return fallback ? fallbackEmoji : null;
  }

  if (!emojiMap) {
    // eslint-disable-next-line @gitlab/require-i18n-strings
    throw new Error('The emoji map is uninitialized or initialization has not completed');
  }

  const lowercaseQuery = query.toLowerCase();
  const name = normalizeEmojiName(lowercaseQuery);

  if (name in emojiMap) {
    return emojiMap[name];
  }

  return fallback ? fallbackEmoji : null;
}

const searchMatchers = {
  // Fuzzy matching compares using a fuzzy matching library
  fuzzy: (value, query) => {
    const score = fuzzaldrinPlus.score(value, query) > 0;
    return { score, success: score > 0 };
  },
  // Contains matching compares by indexOf
  contains: (value, query) => {
    const index = value.indexOf(query.toLowerCase());
    return { index, success: index >= 0 };
  },
  // Exact matching compares by equality
  exact: (value, query) => {
    return { success: value === query.toLowerCase() };
  },
};

const searchPredicates = {
  // Search by name
  name: (matcher, query) => emoji => {
    const m = matcher(emoji.name, query);
    return [{ ...m, emoji, field: emoji.name }];
  },
  // Search by alias
  alias: (matcher, query) => emoji =>
    emoji.aliases.map(alias => {
      const m = matcher(alias, query);
      return { ...m, emoji, field: alias };
    }),
  // Search by description
  description: (matcher, query) => emoji => {
    const m = matcher(emoji.d, query);
    return [{ ...m, emoji, field: emoji.d }];
  },
  // Search by unicode value (always exact)
  unicode: (matcher, query) => emoji => {
    return [{ emoji, field: emoji.e, success: emoji.e === query }];
  },
};

/**
 * Searches emoji by name, aliases, description, and unicode value and returns
 * an array of matches.
 *
 * Behavior is undefined if `opts.fields` is empty or if `opts.match` is fuzzy
 * and the query is empty.
 *
 * Note: `initEmojiMap` must have been called and completed before this method
 * can safely be called.
 *
 * @param {String} query Search query.
 * @param {Object} opts Search options (optional).
 * @param {String[]} opts.fields Fields to search. Choices are 'name', 'alias',
 * 'description', and 'unicode' (value). Default is all (four) fields.
 * @param {String} opts.match Search method to use. Choices are 'exact',
 * 'contains', or 'fuzzy'. All methods are case-insensitive. Exact matching (the
 * default) compares by equality. Contains matching compares by indexOf. Fuzzy
 * matching compares using a fuzzy matching library.
 * @param {Boolean} opts.fallback If true, a fallback emoji will be returned if
 * the result set is empty. Defaults to false.
 * @param {Boolean} opts.raw Returns the raw match data instead of just the
 * matching emoji.
 * @returns {Object[]} A list of emoji that match the query.
 */
export function searchEmoji(query, opts) {
  if (!emojiMap) {
    // eslint-disable-next-line @gitlab/require-i18n-strings
    throw new Error('The emoji map is uninitialized or initialization has not completed');
  }

  const {
    fields = ['name', 'alias', 'description', 'unicode'],
    match = 'exact',
    fallback = false,
    raw = false,
  } = opts || {};

  const fallbackEmoji = emojiMap.grey_question;
  if (!query) {
    if (fallback) {
      return raw ? [{ emoji: fallbackEmoji }] : [fallbackEmoji];
    }

    return [];
  }

  // optimization for an exact match in name and alias
  if (match === 'exact' && new Set([...fields, 'name', 'alias']).size === 2) {
    const emoji = getEmoji(query, fallback);
    return emoji ? [emoji] : [];
  }

  const matcher = searchMatchers[match] || searchMatchers.exact;
  const predicates = fields.map(f => searchPredicates[f](matcher, query));

  const results = Object.values(emojiMap)
    .flatMap(emoji => predicates.flatMap(predicate => predicate(emoji)))
    .filter(r => r.success);

  // Fallback to question mark for unknown emojis
  if (fallback && results.length === 0) {
    return raw ? [{ emoji: fallbackEmoji }] : [fallbackEmoji];
  }

  return raw ? results : results.map(r => r.emoji);
}

let emojiCategoryMap;
export function getEmojiCategoryMap() {
  if (!emojiCategoryMap) {
    emojiCategoryMap = {
      activity: [],
      people: [],
      nature: [],
      food: [],
      travel: [],
      objects: [],
      symbols: [],
      flags: [],
    };
    Object.keys(emojiMap).forEach(name => {
      const emoji = emojiMap[name];
      if (emojiCategoryMap[emoji.c]) {
        emojiCategoryMap[emoji.c].push(name);
      }
    });
  }
  return emojiCategoryMap;
}

export function getEmojiInfo(query) {
  return searchEmoji(query, {
    fields: ['name', 'alias'],
    fallback: true,
  })[0];
}

export function emojiFallbackImageSrc(inputName) {
  const { name } = getEmojiInfo(inputName);
  return `${gon.asset_host || ''}${gon.relative_url_root ||
    ''}/-/emojis/${EMOJI_VERSION}/${name}.png`;
}

export function emojiImageTag(name, src) {
  return `<img class="emoji" title=":${name}:" alt=":${name}:" src="${src}" width="20" height="20" align="absmiddle" />`;
}

export function glEmojiTag(inputName, options) {
  const opts = { sprite: false, ...options };
  const name = normalizeEmojiName(inputName);
  const fallbackSpriteClass = `emoji-${name}`;

  const fallbackSpriteAttribute = opts.sprite
    ? `data-fallback-sprite-class="${fallbackSpriteClass}"`
    : '';

  return `
    <gl-emoji
      ${fallbackSpriteAttribute}
      data-name="${name}"></gl-emoji>
  `;
}
