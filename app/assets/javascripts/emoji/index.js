import { uniq } from 'lodash';
import emojiAliases from 'emojis/aliases.json';
import axios from '../lib/utils/axios_utils';

import AccessorUtilities from '../lib/utils/accessor';

let emojiMap = null;
let emojiPromise = null;
let validEmojiNames = null;

export const EMOJI_VERSION = '1';

const isLocalStorageAvailable = AccessorUtilities.isLocalStorageAccessSafe();

export function initEmojiMap() {
  emojiPromise =
    emojiPromise ||
    new Promise((resolve, reject) => {
      if (emojiMap) {
        resolve(emojiMap);
      } else if (
        isLocalStorageAvailable &&
        window.localStorage.getItem('gl-emoji-map-version') === EMOJI_VERSION &&
        window.localStorage.getItem('gl-emoji-map')
      ) {
        emojiMap = JSON.parse(window.localStorage.getItem('gl-emoji-map'));
        validEmojiNames = [...Object.keys(emojiMap), ...Object.keys(emojiAliases)];
        resolve(emojiMap);
      } else {
        // We load the JSON file direct from the server
        // because it can't be loaded from a CDN due to
        // cross domain problems with JSON
        axios
          .get(`${gon.relative_url_root || ''}/-/emojis/${EMOJI_VERSION}/emojis.json`)
          .then(({ data }) => {
            emojiMap = data;
            validEmojiNames = [...Object.keys(emojiMap), ...Object.keys(emojiAliases)];
            resolve(emojiMap);
            if (isLocalStorageAvailable) {
              window.localStorage.setItem('gl-emoji-map-version', EMOJI_VERSION);
              window.localStorage.setItem('gl-emoji-map', JSON.stringify(emojiMap));
            }
          })
          .catch(err => {
            reject(err);
          });
      }
    });

  return emojiPromise;
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
  return uniq(filterEmojiNames(filter).map(name => normalizeEmojiName(name)));
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
