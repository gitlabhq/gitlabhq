// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/charCodeAt#Fixing_charCodeAt()_to_handle_non-Basic-Multilingual-Plane_characters_if_their_presence_earlier_in_the_string_is_known
function knownCharCodeAt(givenString, index) {
  const str = `${givenString}`;
  const end = str.length;

  const surrogatePairs = /[\uD800-\uDBFF][\uDC00-\uDFFF]/g;
  let idx = index;
  while ((surrogatePairs.exec(str)) != null) {
    const li = surrogatePairs.lastIndex;
    if (li - 2 < idx) {
      idx += 1;
    } else {
      break;
    }
  }

  if (idx >= end || idx < 0) {
    return NaN;
  }

  const code = str.charCodeAt(idx);

  let high;
  let low;
  if (code >= 0xD800 && code <= 0xDBFF) {
    high = code;
    low = str.charCodeAt(idx + 1);
    // Go one further, since one of the "characters" is part of a surrogate pair
    return ((high - 0xD800) * 0x400) + (low - 0xDC00) + 0x10000;
  }
  return code;
}

// See http://stackoverflow.com/a/38901550/796832
// ES5/PhantomJS compatible version of spreading a string
//
// [...'foo'] -> ['f', 'o', 'o']
// [...'🖐🏿'] -> ['🖐', '🏿']
function spreadString(str) {
  const arr = [];
  let i = 0;
  while (!isNaN(knownCharCodeAt(str, i))) {
    const codePoint = knownCharCodeAt(str, i);
    arr.push(String.fromCodePoint(codePoint));
    i += 1;
  }
  return arr;
}

export default spreadString;
