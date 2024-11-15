import { EMOJI_VERSION } from '~/emoji';

// On Windows, flags render as two-letter country codes, see http://emojipedia.org/flags/
const flagACodePoint = 127462; // parseInt('1F1E6', 16)
const flagZCodePoint = 127487; // parseInt('1F1FF', 16)
function isFlagEmoji(emojiUnicode) {
  const cp = emojiUnicode.codePointAt(0);
  // Length 4 because flags are made of 2 characters which are surrogate pairs
  return emojiUnicode.length === 4 && cp >= flagACodePoint && cp <= flagZCodePoint;
}

// Tested on mac OS 10.12.6 and Windows 10 FCU, it renders as two separate characters
const baseFlagCodePoint = 127987; // parseInt('1F3F3', 16)
const rainbowCodePoint = 127752; // parseInt('1F308', 16)
function isRainbowFlagEmoji(emojiUnicode) {
  const characters = Array.from(emojiUnicode);
  // Length 4 because flags are made of 2 characters which are surrogate pairs
  return (
    emojiUnicode.length === 4 &&
    characters[0].codePointAt(0) === baseFlagCodePoint &&
    characters[1].codePointAt(0) === rainbowCodePoint
  );
}

// Chrome <57 renders keycaps oddly
// See https://bugs.chromium.org/p/chromium/issues/detail?id=632294
// Same issue on Windows also fixed in Chrome 57, http://i.imgur.com/rQF7woO.png
function isKeycapEmoji(emojiUnicode) {
  return emojiUnicode.length === 3 && emojiUnicode[2] === '\u20E3';
}

// Check for a skin tone variation emoji which aren't always supported
const tone1 = 127995; // parseInt('1F3FB', 16)
const tone5 = 127999; // parseInt('1F3FF', 16)
function isSkinToneComboEmoji(emojiUnicode) {
  return (
    emojiUnicode.length > 2 &&
    Array.from(emojiUnicode).some((char) => {
      const cp = char.codePointAt(0);
      return cp >= tone1 && cp <= tone5;
    })
  );
}

// macOS supports most skin tone emoji's but
// doesn't support the skin tone versions of horse racing
const horseRacingCodePoint = 127943; // parseInt('1F3C7', 16)
function isHorceRacingSkinToneComboEmoji(emojiUnicode) {
  const firstCharacter = Array.from(emojiUnicode)[0];
  return (
    firstCharacter &&
    firstCharacter.codePointAt(0) === horseRacingCodePoint &&
    isSkinToneComboEmoji(emojiUnicode)
  );
}

// Check for `family_*`, `kiss_*`, `couple_*`
// For ex. Windows 8.1 Firefox 51.0.1, doesn't support these
const zwj = 8205; // parseInt('200D', 16)
const personStartCodePoint = 128102; // parseInt('1F466', 16)
const personEndCodePoint = 128105; // parseInt('1F469', 16)
function isPersonZwjEmoji(emojiUnicode) {
  let hasPersonEmoji = false;
  let hasZwj = false;
  Array.from(emojiUnicode).forEach((character) => {
    const cp = character.codePointAt(0);
    if (cp === zwj) {
      hasZwj = true;
    } else if (cp >= personStartCodePoint && cp <= personEndCodePoint) {
      hasPersonEmoji = true;
    }
  });

  return hasPersonEmoji && hasZwj;
}

// If the backend emoji support is newer, then there may already be emojis in use
// that were not "supported" before but were displayable. In that scenario, we want to
// allow those emojis to be recognized and displayed, until the frontend (usually in the
// following release) is updated.
function isBackendEmojiNewer() {
  return EMOJI_VERSION < gon.emoji_backend_version;
}

// Helper so we don't have to run `isFlagEmoji` twice
// in `isEmojiUnicodeSupported` logic
function checkFlagEmojiSupport(unicodeSupportMap, emojiUnicode) {
  const isFlagResult = isFlagEmoji(emojiUnicode);
  const isRainbowFlagResult = isRainbowFlagEmoji(emojiUnicode);
  return (
    (unicodeSupportMap.flag && isFlagResult) ||
    (unicodeSupportMap.rainbowFlag && isRainbowFlagResult) ||
    (!isFlagResult && !isRainbowFlagResult)
  );
}

// Helper so we don't have to run `isSkinToneComboEmoji` twice
// in `isEmojiUnicodeSupported` logic
function checkSkinToneModifierSupport(unicodeSupportMap, emojiUnicode) {
  const isSkinToneResult = isSkinToneComboEmoji(emojiUnicode);
  return (unicodeSupportMap.skinToneModifier && isSkinToneResult) || !isSkinToneResult;
}

// Helper func so we don't have to run `isHorceRacingSkinToneComboEmoji` twice
// in `isEmojiUnicodeSupported` logic
function checkHorseRacingSkinToneComboEmojiSupport(unicodeSupportMap, emojiUnicode) {
  const isHorseRacingSkinToneResult = isHorceRacingSkinToneComboEmoji(emojiUnicode);
  return (
    (unicodeSupportMap.horseRacing && isHorseRacingSkinToneResult) || !isHorseRacingSkinToneResult
  );
}

// Helper so we don't have to run `isPersonZwjEmoji` twice
// in `isEmojiUnicodeSupported` logic
function checkPersonEmojiSupport(unicodeSupportMap, emojiUnicode) {
  const isPersonZwjResult = isPersonZwjEmoji(emojiUnicode);
  return (unicodeSupportMap.personZwj && isPersonZwjResult) || !isPersonZwjResult;
}

// Takes in a support map and determines whether
// the given unicode emoji is supported on the platform.
//
// Combines all the edge case tests into a one-stop shop method
function isEmojiUnicodeSupported(unicodeSupportMap = {}, emojiUnicode, unicodeVersion) {
  const isOlderThanChrome57 =
    unicodeSupportMap.meta &&
    unicodeSupportMap.meta.isChrome &&
    unicodeSupportMap.meta.chromeVersion < 57;

  // For comments about each scenario, see the comments above each individual respective function
  return (
    (unicodeSupportMap[unicodeVersion] || isBackendEmojiNewer()) &&
    !(isOlderThanChrome57 && isKeycapEmoji(emojiUnicode)) &&
    checkFlagEmojiSupport(unicodeSupportMap, emojiUnicode) &&
    checkSkinToneModifierSupport(unicodeSupportMap, emojiUnicode) &&
    checkHorseRacingSkinToneComboEmojiSupport(unicodeSupportMap, emojiUnicode) &&
    checkPersonEmojiSupport(unicodeSupportMap, emojiUnicode)
  );
}

export {
  isEmojiUnicodeSupported as default,
  isFlagEmoji,
  isRainbowFlagEmoji,
  isKeycapEmoji,
  isSkinToneComboEmoji,
  isHorceRacingSkinToneComboEmoji,
  isPersonZwjEmoji,
};
