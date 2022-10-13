import wrapChildNodes from './wrap_child_nodes';
import linkDependencies from './link_dependencies';
import wrapBidiChars from './wrap_bidi_chars';

export const HLJS_ON_AFTER_HIGHLIGHT = 'after:highlight';

/**
 * Registers our plugins for Highlight.js
 *
 * Plugin API: https://github.com/highlightjs/highlight.js/blob/main/docs/plugin-api.rst
 *
 * @param {Object} hljs - the Highlight.js instance.
 */
export const registerPlugins = (hljs, fileType, rawContent) => {
  hljs.addPlugin({ [HLJS_ON_AFTER_HIGHLIGHT]: wrapChildNodes });
  hljs.addPlugin({ [HLJS_ON_AFTER_HIGHLIGHT]: wrapBidiChars });
  hljs.addPlugin({
    [HLJS_ON_AFTER_HIGHLIGHT]: (result) => linkDependencies(result, fileType, rawContent),
  });
};
