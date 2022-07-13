import { HLJS_ON_AFTER_HIGHLIGHT } from '../constants';
import wrapComments from './wrap_comments';
import linkDependencies from './link_dependencies';

/**
 * Registers our plugins for Highlight.js
 *
 * Plugin API: https://github.com/highlightjs/highlight.js/blob/main/docs/plugin-api.rst
 *
 * @param {Object} hljs - the Highlight.js instance.
 */
export const registerPlugins = (hljs, fileType, rawContent) => {
  hljs.addPlugin({ [HLJS_ON_AFTER_HIGHLIGHT]: wrapComments });
  hljs.addPlugin({
    [HLJS_ON_AFTER_HIGHLIGHT]: (result) => linkDependencies(result, fileType, rawContent),
  });
};
