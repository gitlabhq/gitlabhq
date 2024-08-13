/**
 * Highlight.js plugin for wrapping lines in the correct classes and attributes.
 * Needed for things like hash highlighting to work.
 *
 * Plugin API: https://github.com/highlightjs/highlight.js/blob/main/docs/plugin-api.rst
 *
 * @param content - represents the highlighted content
 * @param number - represents the highlighted line number
 * @param language - represents the highlighted language
 */

function wrapLine(content, number, language) {
  return `<div id="LC${number}" lang="${language}" class="line">${content}</div>`;
}

export default (result) => {
  // eslint-disable-next-line no-param-reassign
  result.value = result.value
    .split(/\r?\n/)
    .map((content, index) => wrapLine(content, index + 1, result.language))
    .join('\n');
};
