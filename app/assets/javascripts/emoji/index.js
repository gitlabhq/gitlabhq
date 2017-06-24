import emojiMap from 'emojis/digests.json';
import emojiAliases from 'emojis/aliases.json';
import getUnicodeSupportMap from './unicode_support_map';
import isEmojiUnicodeSupported from './is_emoji_unicode_supported';

const validEmojiNames = [...Object.keys(emojiMap), ...Object.keys(emojiAliases)];

function normalizeEmojiName(name) {
  return Object.prototype.hasOwnProperty.call(emojiAliases, name) ? emojiAliases[name] : name;
}

function isEmojiNameValid(name) {
  return validEmojiNames.indexOf(name) >= 0;
}

export {
  emojiMap,
  emojiAliases,
  normalizeEmojiName,
  getUnicodeSupportMap,
  isEmojiNameValid,
  isEmojiUnicodeSupported,
};
