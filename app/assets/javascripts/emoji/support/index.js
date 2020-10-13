import isEmojiUnicodeSupported from './is_emoji_unicode_supported';
import getUnicodeSupportMap from './unicode_support_map';

// cache browser support map between calls
let browserUnicodeSupportMap;

export default function isEmojiUnicodeSupportedByBrowser(emojiUnicode, unicodeVersion) {
  // Skipping the map creation for Bots + RSPec
  if (
    navigator.userAgent.indexOf('HeadlessChrome') > -1 ||
    navigator.userAgent.indexOf('Lighthouse') > -1 ||
    navigator.userAgent.indexOf('Speedindex') > -1
  ) {
    return true;
  }
  browserUnicodeSupportMap = browserUnicodeSupportMap || getUnicodeSupportMap();
  return isEmojiUnicodeSupported(browserUnicodeSupportMap, emojiUnicode, unicodeVersion);
}
