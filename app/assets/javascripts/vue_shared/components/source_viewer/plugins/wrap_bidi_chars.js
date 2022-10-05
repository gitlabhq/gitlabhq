import {
  BIDI_CHARS,
  BIDI_CHARS_CLASS_LIST,
  BIDI_CHAR_TOOLTIP,
} from '~/vue_shared/components/source_viewer/constants';

/**
 * Highlight.js plugin for wrapping BIDI chars.
 * This ensures potentially dangerous BIDI characters are highlighted.
 *
 * Plugin API: https://github.com/highlightjs/highlight.js/blob/main/docs/plugin-api.rst
 *
 * @param {Object} Result - an object that represents the highlighted result from Highlight.js
 */

function wrapBidiChar(bidiChar) {
  return `<span class="${BIDI_CHARS_CLASS_LIST}" title="${BIDI_CHAR_TOOLTIP}">${bidiChar}</span>`;
}

export default (result) => {
  let { value } = result;
  BIDI_CHARS.forEach((bidiChar) => {
    if (value.includes(bidiChar)) {
      value = value.replace(bidiChar, wrapBidiChar(bidiChar));
    }
  });

  // eslint-disable-next-line no-param-reassign
  result.value = value; // Highlight.js expects the result param to be mutated for plugins to work
};
