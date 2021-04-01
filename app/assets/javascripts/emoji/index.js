import { escape, minBy } from 'lodash';
import emojiAliases from 'emojis/aliases.json';
import AccessorUtilities from '../lib/utils/accessor';
import axios from '../lib/utils/axios_utils';
import { CATEGORY_ICON_MAP, FREQUENTLY_USED_KEY } from './constants';

let emojiMap = null;
let validEmojiNames = null;
export const FALLBACK_EMOJI_KEY = 'grey_question';

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

async function loadEmojiWithNames() {
  return Object.entries(await loadEmoji()).reduce((acc, [key, value]) => {
    acc[key] = { ...value, name: key };

    return acc;
  }, {});
}

async function prepareEmojiMap() {
  emojiMap = await loadEmojiWithNames();
  validEmojiNames = [...Object.keys(emojiMap), ...Object.keys(emojiAliases)];
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
  if (!emojiMap) {
    // eslint-disable-next-line @gitlab/require-i18n-strings
    throw new Error('The emoji map is uninitialized or initialization has not completed');
  }

  return name in emojiMap || name in emojiAliases;
}

export function getAllEmoji() {
  return emojiMap;
}

function getAliasesMatchingQuery(query) {
  return Object.keys(emojiAliases)
    .filter((alias) => alias.includes(query))
    .reduce((map, alias) => {
      const emojiName = emojiAliases[alias];
      const score = alias.indexOf(query);

      const prev = map.get(emojiName);
      // overwrite if we beat the previous score or we're more alphabetical
      const shouldSet =
        !prev ||
        prev.score > score ||
        (prev.score === score && prev.alias.localeCompare(alias) > 0);

      if (shouldSet) {
        map.set(emojiName, { score, alias });
      }

      return map;
    }, new Map());
}

function getUnicodeMatch(emoji, query) {
  if (emoji.e === query) {
    return { score: 0, field: 'e', fieldValue: emoji.name, emoji };
  }

  return null;
}

function getDescriptionMatch(emoji, query) {
  if (emoji.d.includes(query)) {
    return { score: emoji.d.indexOf(query), field: 'd', fieldValue: emoji.d, emoji };
  }

  return null;
}

function getAliasMatch(emoji, matchingAliases) {
  if (matchingAliases.has(emoji.name)) {
    const { score, alias } = matchingAliases.get(emoji.name);

    return { score, field: 'alias', fieldValue: alias, emoji };
  }

  return null;
}

function getNameMatch(emoji, query) {
  if (emoji.name.includes(query)) {
    return {
      score: emoji.name.indexOf(query),
      field: 'name',
      fieldValue: emoji.name,
      emoji,
    };
  }

  return null;
}

export function searchEmoji(query) {
  const lowercaseQuery = query ? `${query}`.toLowerCase() : '';

  const matchingAliases = getAliasesMatchingQuery(lowercaseQuery);

  return Object.values(emojiMap)
    .map((emoji) => {
      const matches = [
        getUnicodeMatch(emoji, query),
        getDescriptionMatch(emoji, lowercaseQuery),
        getAliasMatch(emoji, matchingAliases),
        getNameMatch(emoji, lowercaseQuery),
      ].filter(Boolean);

      return minBy(matches, (x) => x.score);
    })
    .filter(Boolean);
}

export function sortEmoji(items) {
  // Sort results by index of and string comparison
  return [...items].sort((a, b) => a.score - b.score || a.fieldValue.localeCompare(b.fieldValue));
}

export const CATEGORY_NAMES = Object.keys(CATEGORY_ICON_MAP);

let emojiCategoryMap;
export function getEmojiCategoryMap() {
  if (!emojiCategoryMap) {
    emojiCategoryMap = CATEGORY_NAMES.reduce((acc, category) => {
      if (category === FREQUENTLY_USED_KEY) {
        return acc;
      }
      return { ...acc, [category]: [] };
    }, {});
    Object.keys(emojiMap).forEach((name) => {
      const emoji = emojiMap[name];
      if (emojiCategoryMap[emoji.c]) {
        emojiCategoryMap[emoji.c].push(name);
      }
    });
  }
  return emojiCategoryMap;
}

/**
 * Retrieves an emoji by name
 *
 * @param {String} query The emoji name
 * @param {Boolean} fallback If true, a fallback emoji will be returned if the
 * named emoji does not exist.
 * @returns {Object} The matching emoji.
 */
export function getEmojiInfo(query, fallback = true) {
  if (!emojiMap) {
    // eslint-disable-next-line @gitlab/require-i18n-strings
    throw new Error('The emoji map is uninitialized or initialization has not completed');
  }

  const lowercaseQuery = query ? `${query}`.toLowerCase() : '';
  const name = normalizeEmojiName(lowercaseQuery);

  if (name in emojiMap) {
    return emojiMap[name];
  }

  return fallback ? emojiMap[FALLBACK_EMOJI_KEY] : null;
}

export function emojiFallbackImageSrc(inputName) {
  const { name } = getEmojiInfo(inputName);
  return `${gon.asset_host || ''}${
    gon.relative_url_root || ''
  }/-/emojis/${EMOJI_VERSION}/${name}.png`;
}

export function emojiImageTag(name, src) {
  return `<img class="emoji" title=":${name}:" alt=":${name}:" src="${src}" width="20" height="20" align="absmiddle" />`;
}

export function glEmojiTag(inputName, options) {
  const opts = { sprite: false, ...options };
  const name = normalizeEmojiName(inputName);
  const fallbackSpriteClass = `emoji-${name}`;

  const fallbackSpriteAttribute = opts.sprite
    ? `data-fallback-sprite-class="${escape(fallbackSpriteClass)}" `
    : '';

  return `<gl-emoji ${fallbackSpriteAttribute}data-name="${escape(name)}"></gl-emoji>`;
}
