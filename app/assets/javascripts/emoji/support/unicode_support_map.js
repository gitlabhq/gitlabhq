import AccessorUtilities from '../../lib/utils/accessor';

const GL_EMOJI_VERSION = '0.2.0';

const unicodeSupportTestMap = {
  // man, student (emojione does not have any of these yet), http://emojipedia.org/emoji-zwj-sequences/
  // occupationZwj: '\u{1F468}\u{200D}\u{1F393}',
  // woman, biking (emojione does not have any of these yet), http://emojipedia.org/emoji-zwj-sequences/
  // sexZwj: '\u{1F6B4}\u{200D}\u{2640}',
  // family_mwgb
  // Windows 8.1, Firefox 51.0.1 does not support `family_`, `kiss_`, `couple_`
  personZwj: '\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}\u{200D}\u{1F466}',
  // horse_racing_tone5
  // Special case that is not supported on macOS 10.12 even though `skinToneModifier` succeeds
  horseRacing: '\u{1F3C7}\u{1F3FF}',
  // US flag, http://emojipedia.org/flags/
  flag: '\u{1F1FA}\u{1F1F8}',
  rainbowFlag: '\u{1F3F3}\u{1F308}',
  // http://emojipedia.org/modifiers/
  skinToneModifier: [
    // spy_tone5
    '\u{1F575}\u{1F3FF}',
    // person_with_ball_tone5
    '\u{26F9}\u{1F3FF}',
    // angel_tone5
    '\u{1F47C}\u{1F3FF}',
  ],
  // rofl, http://emojipedia.org/unicode-9.0/
  '9.0': '\u{1F923}',
  // metal, http://emojipedia.org/unicode-8.0/
  '8.0': '\u{1F918}',
  // spy, http://emojipedia.org/unicode-7.0/
  '7.0': '\u{1F575}',
  // expressionless, http://emojipedia.org/unicode-6.1/
  6.1: '\u{1F611}',
  // japanese_goblin, http://emojipedia.org/unicode-6.0/
  '6.0': '\u{1F47A}',
  // sailboat, http://emojipedia.org/unicode-5.2/
  5.2: '\u{26F5}',
  // mahjong, http://emojipedia.org/unicode-5.1/
  5.1: '\u{1F004}',
  // gear, http://emojipedia.org/unicode-4.1/
  4.1: '\u{2699}',
  // zap, http://emojipedia.org/unicode-4.0/
  '4.0': '\u{26A1}',
  // recycle, http://emojipedia.org/unicode-3.2/
  3.2: '\u{267B}',
  // information_source, http://emojipedia.org/unicode-3.0/
  '3.0': '\u{2139}',
  // heart, http://emojipedia.org/unicode-1.1/
  1.1: '\u{2764}',
};

function checkPixelInImageDataArray(pixelOffset, imageDataArray) {
  // `4 *` because RGBA
  const indexOffset = 4 * pixelOffset;
  const hasColor =
    imageDataArray[indexOffset + 0] ||
    imageDataArray[indexOffset + 1] ||
    imageDataArray[indexOffset + 2];
  const isVisible = imageDataArray[indexOffset + 3];
  // Check for some sort of color other than black
  if (hasColor && isVisible) {
    return true;
  }
  return false;
}

const chromeMatches = navigator.userAgent.match(/Chrom(?:e|ium)\/([0-9]+)\./);
const isChrome = chromeMatches && chromeMatches.length > 0;
const chromeVersion = chromeMatches && chromeMatches[1] && parseInt(chromeMatches[1], 10);

// We use 16px because mobile Safari (iOS 9.3) doesn't properly scale emojis :/
// See 32px, https://i.imgur.com/htY6Zym.png
// See 16px, https://i.imgur.com/FPPsIF8.png
const fontSize = 16;
function generateUnicodeSupportMap(testMap) {
  const testMapKeys = Object.keys(testMap);
  const numTestEntries = testMapKeys.reduce((list, testKey) => list.concat(testMap[testKey]), [])
    .length;

  const canvas = document.createElement('canvas');
  (window.gl || window).testEmojiUnicodeSupportMapCanvas = canvas;
  const ctx = canvas.getContext('2d');
  canvas.width = 2 * fontSize;
  canvas.height = numTestEntries * fontSize;
  ctx.fillStyle = '#000000';
  ctx.textBaseline = 'middle';
  ctx.font = `${fontSize}px "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol"`;
  // Write each emoji to the canvas vertically
  let writeIndex = 0;
  testMapKeys.forEach(testKey => {
    const testEntry = testMap[testKey];
    [].concat(testEntry).forEach(emojiUnicode => {
      ctx.fillText(emojiUnicode, 0, writeIndex * fontSize + fontSize / 2);
      writeIndex += 1;
    });
  });

  // Read from the canvas
  const resultMap = {};
  let readIndex = 0;
  testMapKeys.forEach(testKey => {
    const testEntry = testMap[testKey];
    // This needs to be a `reduce` instead of `every` because we need to
    // keep the `readIndex` in sync from the writes by running all entries
    const isTestSatisfied = [].concat(testEntry).reduce(isSatisfied => {
      // Sample along the vertical-middle for a couple of characters
      const imageData = ctx.getImageData(0, readIndex * fontSize + fontSize / 2, 2 * fontSize, 1)
        .data;

      let isValidEmoji = false;
      for (let currentPixel = 0; currentPixel < 64; currentPixel += 1) {
        const isLookingAtFirstChar = currentPixel < fontSize;
        const isLookingAtSecondChar = currentPixel >= fontSize + fontSize / 2;
        // Check for the emoji somewhere along the row
        if (isLookingAtFirstChar && checkPixelInImageDataArray(currentPixel, imageData)) {
          isValidEmoji = true;

          // Check to see that nothing is rendered next to the first character
          // to ensure that the ZWJ sequence rendered as one piece
        } else if (isLookingAtSecondChar && checkPixelInImageDataArray(currentPixel, imageData)) {
          isValidEmoji = false;
          break;
        }
      }

      readIndex += 1;
      return isSatisfied && isValidEmoji;
    }, true);

    resultMap[testKey] = isTestSatisfied;
  });

  resultMap.meta = {
    isChrome,
    chromeVersion,
  };

  return resultMap;
}

export default function getUnicodeSupportMap() {
  const isLocalStorageAvailable = AccessorUtilities.isLocalStorageAccessSafe();

  let glEmojiVersionFromCache;
  let userAgentFromCache;
  if (isLocalStorageAvailable) {
    glEmojiVersionFromCache = window.localStorage.getItem('gl-emoji-version');
    userAgentFromCache = window.localStorage.getItem('gl-emoji-user-agent');
  }

  let unicodeSupportMap;
  try {
    unicodeSupportMap = JSON.parse(window.localStorage.getItem('gl-emoji-unicode-support-map'));
  } catch (err) {
    // swallow
  }

  if (
    !unicodeSupportMap ||
    glEmojiVersionFromCache !== GL_EMOJI_VERSION ||
    userAgentFromCache !== navigator.userAgent
  ) {
    unicodeSupportMap = generateUnicodeSupportMap(unicodeSupportTestMap);

    if (isLocalStorageAvailable) {
      window.localStorage.setItem('gl-emoji-version', GL_EMOJI_VERSION);
      window.localStorage.setItem('gl-emoji-user-agent', navigator.userAgent);
      window.localStorage.setItem(
        'gl-emoji-unicode-support-map',
        JSON.stringify(unicodeSupportMap),
      );
    }
  }

  return unicodeSupportMap;
}
