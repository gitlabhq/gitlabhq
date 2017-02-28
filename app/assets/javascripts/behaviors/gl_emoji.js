const installCustomElements = require('document-register-element');
const emojiMap = require('emoji-map');
const emojiAliases = require('emoji-aliases');
const generatedUnicodeSupportMap = require('./gl_emoji/unicode_support_map');
const spreadString = require('./gl_emoji/spread_string');

installCustomElements(window);

function emojiImageTag(name, src) {
  return `<img class="emoji" title=":${name}:" alt=":${name}:" src="${src}" width="20" height="20" align="absmiddle" />`;
}

const glEmojiTagDefaults = {
  sprite: false,
  forceFallback: false,
};
function glEmojiTag(inputName, options) {
  const opts = Object.assign({}, glEmojiTagDefaults, options);
  const name = emojiAliases[inputName] || inputName;
  const emojiInfo = emojiMap[name];
  const fallbackImageSrc = `${gon.relative_url_root || ''}/assets/emoji/${name}-${emojiInfo.digest}.png`;
  const fallbackSpriteClass = `emoji-${name}`;

  const classList = [];
  if (opts.forceFallback && opts.sprite) {
    classList.push('emoji-icon');
    classList.push(fallbackSpriteClass);
  }
  const classAttribute = classList.length > 0 ? `class="${classList.join(' ')}"` : '';
  const fallbackSpriteAttribute = opts.sprite ? `data-fallback-sprite-class="${fallbackSpriteClass}"` : '';
  let contents = emojiInfo.moji;
  if (opts.forceFallback && !opts.sprite) {
    contents = emojiImageTag(name, fallbackImageSrc);
  }

  return `
  <gl-emoji
    ${classAttribute}
    data-name="${name}"
    data-fallback-src="${fallbackImageSrc}"
    ${fallbackSpriteAttribute}
    data-unicode-version="${emojiInfo.unicodeVersion}"
  >
    ${contents}
  </gl-emoji>
  `;
}

// On Windows, flags render as two-letter country codes, see http://emojipedia.org/flags/
const flagACodePoint = 127462; // parseInt('1F1E6', 16)
const flagZCodePoint = 127487; // parseInt('1F1FF', 16)
function isFlagEmoji(emojiUnicode) {
  const cp = emojiUnicode.codePointAt(0);
  // Length 4 because flags are made of 2 characters which are surrogate pairs
  return emojiUnicode.length === 4 && cp >= flagACodePoint && cp <= flagZCodePoint;
}

// Chrome <57 renders keycaps oddly
// See https://bugs.chromium.org/p/chromium/issues/detail?id=632294
// Same issue on Windows also fixed in Chrome 57, http://i.imgur.com/rQF7woO.png
function isKeycapEmoji(emojiUnicode) {
  return emojiUnicode.length === 3 && emojiUnicode[2] === '\u20E3';
}

// Check for a skin tone variation emoji which aren't always supported
const tone1 = 127995;// parseInt('1F3FB', 16)
const tone5 = 127999;// parseInt('1F3FF', 16)
function isSkinToneComboEmoji(emojiUnicode) {
  return emojiUnicode.length > 2 && spreadString(emojiUnicode).some((char) => {
    const cp = char.codePointAt(0);
    return cp >= tone1 && cp <= tone5;
  });
}

// macOS supports most skin tone emoji's but
// doesn't support the skin tone versions of horse racing
const horseRacingCodePoint = 127943;// parseInt('1F3C7', 16)
function isHorceRacingSkinToneComboEmoji(emojiUnicode) {
  return spreadString(emojiUnicode)[0].codePointAt(0) === horseRacingCodePoint &&
    isSkinToneComboEmoji(emojiUnicode);
}

// Check for `family_*`, `kiss_*`, `couple_*`
// For ex. Windows 8.1 Firefox 51.0.1, doesn't support these
const zwj = 8205; // parseInt('200D', 16)
const personStartCodePoint = 128102; // parseInt('1F466', 16)
const personEndCodePoint = 128105; // parseInt('1F469', 16)
function isPersonZwjEmoji(emojiUnicode) {
  let hasPersonEmoji = false;
  let hasZwj = false;
  spreadString(emojiUnicode).forEach((character) => {
    const cp = character.codePointAt(0);
    if (cp === zwj) {
      hasZwj = true;
    } else if (cp >= personStartCodePoint && cp <= personEndCodePoint) {
      hasPersonEmoji = true;
    }
  });

  return hasPersonEmoji && hasZwj;
}

// Helper so we don't have to run `isFlagEmoji` twice
// in `isEmojiUnicodeSupported` logic
function checkFlagEmojiSupport(unicodeSupportMap, emojiUnicode) {
  const isFlagResult = isFlagEmoji(emojiUnicode);
  return (
    (unicodeSupportMap.flag && isFlagResult) ||
    !isFlagResult
  );
}

// Helper so we don't have to run `isSkinToneComboEmoji` twice
// in `isEmojiUnicodeSupported` logic
function checkSkinToneModifierSupport(unicodeSupportMap, emojiUnicode) {
  const isSkinToneResult = isSkinToneComboEmoji(emojiUnicode);
  return (
    (unicodeSupportMap.skinToneModifier && isSkinToneResult) ||
    !isSkinToneResult
  );
}

// Helper func so we don't have to run `isHorceRacingSkinToneComboEmoji` twice
// in `isEmojiUnicodeSupported` logic
function checkHorseRacingSkinToneComboEmojiSupport(unicodeSupportMap, emojiUnicode) {
  const isHorseRacingSkinToneResult = isHorceRacingSkinToneComboEmoji(emojiUnicode);
  return (
    (unicodeSupportMap.horseRacing && isHorseRacingSkinToneResult) ||
    !isHorseRacingSkinToneResult
  );
}

// Helper so we don't have to run `isPersonZwjEmoji` twice
// in `isEmojiUnicodeSupported` logic
function checkPersonEmojiSupport(unicodeSupportMap, emojiUnicode) {
  const isPersonZwjResult = isPersonZwjEmoji(emojiUnicode);
  return (
    (unicodeSupportMap.personZwj && isPersonZwjResult) ||
    !isPersonZwjResult
  );
}

// Takes in a support map and determines whether
// the given unicode emoji is supported on the platform.
//
// Combines all the edge case tests into a one-stop shop method
function isEmojiUnicodeSupported(unicodeSupportMap = {}, emojiUnicode, unicodeVersion) {
  const isOlderThanChrome57 = unicodeSupportMap.meta && unicodeSupportMap.meta.isChrome &&
    unicodeSupportMap.meta.chromeVersion < 57;

  // For comments about each scenario, see the comments above each individual respective function
  return unicodeSupportMap[unicodeVersion] &&
    !(isOlderThanChrome57 && isKeycapEmoji(emojiUnicode)) &&
    checkFlagEmojiSupport(unicodeSupportMap, emojiUnicode) &&
    checkSkinToneModifierSupport(unicodeSupportMap, emojiUnicode) &&
    checkHorseRacingSkinToneComboEmojiSupport(unicodeSupportMap, emojiUnicode) &&
    checkPersonEmojiSupport(unicodeSupportMap, emojiUnicode);
}

const GlEmojiElementProto = Object.create(HTMLElement.prototype);
GlEmojiElementProto.createdCallback = function createdCallback() {
  const emojiUnicode = this.textContent.trim();
  const {
    unicodeVersion,
    fallbackSrc,
    fallbackSpriteClass,
  } = this.dataset;

  const isEmojiUnicode = this.childNodes && Array.prototype.every.call(
    this.childNodes,
    childNode => childNode.nodeType === 3,
  );
  const hasImageFallback = fallbackSrc && fallbackSrc.length > 0;
  const hasCssSpriteFalback = fallbackSpriteClass && fallbackSpriteClass.length > 0;

  if (
    isEmojiUnicode &&
    !isEmojiUnicodeSupported(generatedUnicodeSupportMap, emojiUnicode, unicodeVersion)
  ) {
    // CSS sprite fallback takes precedence over image fallback
    if (hasCssSpriteFalback) {
      // IE 11 doesn't like adding multiple at once :(
      this.classList.add('emoji-icon');
      this.classList.add(fallbackSpriteClass);
    } else if (hasImageFallback) {
      const emojiName = this.dataset.name;
      this.innerHTML = emojiImageTag(emojiName, fallbackSrc);
    }
  }
};

document.registerElement('gl-emoji', {
  prototype: GlEmojiElementProto,
});

module.exports = {
  emojiImageTag,
  glEmojiTag,
  isEmojiUnicodeSupported,
  isFlagEmoji,
  isKeycapEmoji,
  isSkinToneComboEmoji,
  isHorceRacingSkinToneComboEmoji,
  isPersonZwjEmoji,
};
