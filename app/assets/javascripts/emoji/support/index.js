import isEmojiUnicodeSupported from './is_emoji_unicode_supported';
import getUnicodeSupportMap from './unicode_support_map';

// cache browser support map between calls
let browserUnicodeSupportMap;

export default function isEmojiUnicodeSupportedByBrowser(emojiUnicode, unicodeVersion) {
  browserUnicodeSupportMap = browserUnicodeSupportMap || getUnicodeSupportMap();
  return isEmojiUnicodeSupported(browserUnicodeSupportMap, emojiUnicode, unicodeVersion);
}
