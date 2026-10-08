import wrapChildNodes from './wrap_child_nodes';
import wrapBidiChars from './wrap_bidi_chars';
import linkDependencies from './link_dependencies';
import wrapLines from './wrap_lines';

const HLJS_ON_AFTER_HIGHLIGHT = 'after:highlight';

// Registers our plugins for Highlight.js
// Plugin API: https://github.com/highlightjs/highlight.js/blob/main/docs/plugin-api.rst
export const highlightPlugins = (fileType, rawContent, shouldWrapLines) => {
  const plugins = [
    wrapChildNodes,
    wrapBidiChars,
    (result) => linkDependencies(result, fileType, rawContent),
  ];
  if (shouldWrapLines) {
    plugins.push(wrapLines);
  }
  return plugins;
};

export const registerPlugins = (hljs, plugins) => {
  if (!plugins) {
    return;
  }
  for (const plugin of plugins) {
    hljs.addPlugin({ [HLJS_ON_AFTER_HIGHLIGHT]: plugin });
  }
};
