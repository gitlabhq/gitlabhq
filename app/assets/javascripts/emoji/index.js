import _ from 'underscore';
import emojiMap from 'emojis/digests.json';
import emojiAliases from 'emojis/aliases.json';

export const validEmojiNames = [...Object.keys(emojiMap), ...Object.keys(emojiAliases)];

export function normalizeEmojiName(name) {
  return Object.prototype.hasOwnProperty.call(emojiAliases, name) ? emojiAliases[name] : name;
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
    Object.keys(emojiMap).forEach((name) => {
      const emoji = emojiMap[name];
      if (emojiCategoryMap[emoji.category]) {
        emojiCategoryMap[emoji.category].push(name);
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
  const { name, digest } = getEmojiInfo(inputName);
  return `${gon.asset_host || ''}${gon.relative_url_root || ''}/assets/emoji/${name}-${digest}.png`;
}

export function emojiImageTag(name, src) {
  return `<img class="emoji" title=":${name}:" alt=":${name}:" src="${src}" />`;
}

export function glEmojiTag(inputName, options) {
  const opts = {
    sprite: false,
    custom: false,
    forceFallback: false,
    fallbackImageSrc: null,
    ...options,
  };
  const emojiInfo = opts.custom ? {} : getEmojiInfo(inputName);
  const name = opts.custom ? inputName : emojiInfo.name;

  const fallbackImageSrc = opts.fallbackImageSrc || emojiFallbackImageSrc(name);
  const fallbackSpriteClass = `emoji-${name}`;

  const classList = [];
  if (opts.forceFallback && opts.sprite) {
    classList.push('emoji-icon');
    classList.push(fallbackSpriteClass);
  }
  const classAttribute = classList.length > 0 ? `class="${classList.join(' ')}"` : '';
  const fallbackSourceAttribute = !opts.custom ? `data-fallback-src="${fallbackImageSrc}"` : '';
  const fallbackSpriteAttribute = opts.sprite ? `data-fallback-sprite-class="${fallbackSpriteClass}"` : '';
  const unicodeVersionAttribute = !opts.custom ? `data-unicode-version="${emojiInfo.unicodeVersion}"` : '';
  let contents = emojiInfo.moji;
  if (opts.custom || (opts.forceFallback && !opts.sprite)) {
    contents = emojiImageTag(name, fallbackImageSrc);
  }

  return `
    <gl-emoji
      ${classAttribute}
      data-name="${name}"
      ${fallbackSourceAttribute}
      ${fallbackSpriteAttribute}
      ${unicodeVersionAttribute}
      title="${opts.custom ? name : emojiInfo.description}"
    >
      ${contents}
    </gl-emoji>
  `;
}
