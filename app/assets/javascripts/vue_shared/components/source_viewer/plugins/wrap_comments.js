import { HLJS_COMMENT_SELECTOR } from '../constants';

const createWrapper = (content) => {
  const span = document.createElement('span');
  span.className = HLJS_COMMENT_SELECTOR;

  // eslint-disable-next-line no-unsanitized/property
  span.innerHTML = content;
  return span.outerHTML;
};

/**
 * Highlight.js plugin for wrapping multi-line comments in the `hljs-comment` class.
 * This ensures that multi-line comments are rendered correctly in the GitLab UI.
 *
 * Plugin API: https://github.com/highlightjs/highlight.js/blob/main/docs/plugin-api.rst
 *
 * @param {Object} Result - an object that represents the highlighted result from Highlight.js
 */
export default (result) => {
  if (!result.value.includes(HLJS_COMMENT_SELECTOR)) return;

  let wrapComment = false;

  // eslint-disable-next-line no-param-reassign
  result.value = result.value // Highlight.js expects the result param to be mutated for plugins to work
    .split('\n')
    .map((lineContent) => {
      const includesClosingTag = lineContent.includes('</span>');
      if (lineContent.includes(HLJS_COMMENT_SELECTOR) && !includesClosingTag) {
        wrapComment = true;
        return lineContent;
      }
      const line = wrapComment ? createWrapper(lineContent) : lineContent;
      if (includesClosingTag) {
        wrapComment = false;
      }
      return line;
    })
    .join('\n');
};
