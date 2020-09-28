import { uniq } from 'lodash';
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

/**
 * Search emoji by name or alias. Returns a normalized, deduplicated list of
 * names.
 *
 * Calling with an empty filter returns an empty array.
 *
 * @param {String}
 * @returns {Array}
 */
export function queryEmojiNames(filter) {
  const matches = fuzzaldrinPlus.filter(validEmojiNames, filter);
  return uniq(matches.map(name => normalizeEmojiName(name)));
}

/**
 * Searches emoji by name, alias, description, and unicode value and returns an
 * array of matches.
 *
 * Note: `initEmojiMap` must have been called and completed before this method
 * can safely be called.
 *
 * @param {String} query The search query
 * @returns {Object[]} A list of emoji that match the query
 */
export function searchEmoji(query) {
  if (!emojiMap)
    // eslint-disable-next-line @gitlab/require-i18n-strings
    throw new Error('The emoji map is uninitialized or initialization has not completed');

  const matches = s => fuzzaldrinPlus.score(s, query) > 0;

  // Search emoji
  return Object.values(emojiMap).filter(
    emoji =>
      // by name
      matches(emoji.name) ||
      // by alias
      emoji.aliases.some(matches) ||
      // by description
      matches(emoji.d) ||
      // by unicode value
      query === emoji.e,
  );
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
  let name = normalizeEmojiName(query);
  let emojiInfo = emojiMap[name];

  // Fallback to question mark for unknown emojis
  if (!emojiInfo) {
    name = 'grey_question';
    emojiInfo = emojiMap[name];
  }

  return { ...emojiInfo, name };
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
