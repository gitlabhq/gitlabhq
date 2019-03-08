import _ from 'underscore';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import emojiAliases from 'emojis/aliases.json';
import axios from '../lib/utils/axios_utils';

import AccessorUtilities from '../lib/utils/accessor';

let emojiMap = null;
let validEmojiNames = null;

export const EMOJI_VERSION = '1';
const EMOJI_VERSION_LOCALSTORAGE = `EMOJIS_${EMOJI_VERSION}`;

const isLocalStorageAvailable = AccessorUtilities.isLocalStorageAccessSafe();

export function initEmojiMap() {
  return new Promise((resolve, reject) => {
    if (emojiMap) {
      resolve(emojiMap);
    } else if (isLocalStorageAvailable && window.localStorage.getItem(EMOJI_VERSION_LOCALSTORAGE)) {
      emojiMap = JSON.parse(window.localStorage.getItem(EMOJI_VERSION_LOCALSTORAGE));
      validEmojiNames = [...Object.keys(emojiMap), ...Object.keys(emojiAliases)];
      resolve(emojiMap);
    } else {
      // We load the JSON from server
      axios
        .get(
          `${gon.asset_host || ''}${gon.relative_url_root ||
            ''}/-/emojis/${EMOJI_VERSION}/emojis.json`,
        )
        .then(({ data }) => {
          emojiMap = data;
          validEmojiNames = [...Object.keys(emojiMap), ...Object.keys(emojiAliases)];
          resolve(emojiMap);
          if (isLocalStorageAvailable) {
            window.localStorage.setItem(EMOJI_VERSION_LOCALSTORAGE, JSON.stringify(emojiMap));
          }
        })
        .catch(err => {
          createFlash(s__('Emojis|Something went wrong while loading emojis.'));
          reject(err);
        });
    }
  });
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

export function filterEmojiNames(filter) {
  const match = filter.toLowerCase();
  return validEmojiNames.filter(name => name.indexOf(match) >= 0);
}

export function filterEmojiNamesByAlias(filter) {
  return _.uniq(filterEmojiNames(filter).map(name => normalizeEmojiName(name)));
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
  const opts = { sprite: false, forceFallback: false, ...options };
  const name = normalizeEmojiName(inputName);

  const fallbackSpriteClass = `emoji-${name}`;

  const classList = [];
  if (opts.forceFallback && opts.sprite) {
    classList.push('emoji-icon');
    classList.push(fallbackSpriteClass);
  }
  const classAttribute = classList.length > 0 ? `class="${classList.join(' ')}"` : '';

  const fallbackSpriteAttribute = opts.sprite
    ? `data-fallback-sprite-class="${fallbackSpriteClass}"`
    : '';
  const forceFallbackAttribute = opts.forceFallback ? 'data-force-fallback="true"' : '';

  return `
    <gl-emoji
      ${classAttribute}
      data-name="${name}"
      ${fallbackSpriteAttribute}
      ${forceFallbackAttribute}
    >
    </gl-emoji>
  `;
}
