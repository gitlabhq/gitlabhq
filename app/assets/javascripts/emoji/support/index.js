import isEmojiUnicodeSupported from './is_emoji_unicode_supported';
import getUnicodeSupportMap from './unicode_support_map';

// cache browser support map between calls
let browserUnicodeSupportMap;

export default function isEmojiUnicodeSupportedByBrowser(emojiUnicode, unicodeVersion) {
  // Our Spec browser would fail producing emoji maps
  if (/\bHeadlessChrome\//.test(navigator.userAgent)) return true;

  browserUnicodeSupportMap = browserUnicodeSupportMap || getUnicodeSupportMap();
  return isEmojiUnicodeSupported(browserUnicodeSupportMap, emojiUnicode, unicodeVersion);
}
