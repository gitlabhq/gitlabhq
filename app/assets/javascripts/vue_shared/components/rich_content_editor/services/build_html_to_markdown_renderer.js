import { defaults, repeat } from 'lodash';

const DEFAULTS = {
  subListIndentSpaces: 4,
};

const countIndentSpaces = text => {
  const matches = text.match(/^\s+/m);

  return matches ? matches[0].length : 0;
};

const buildHTMLToMarkdownRender = (baseRenderer, formattingPreferences = {}) => {
  const { subListIndentSpaces } = defaults(formattingPreferences, DEFAULTS);
  // eslint-disable-next-line @gitlab/require-i18n-strings
  const sublistNode = 'LI OL, LI UL';

  return {
    TEXT_NODE(node) {
      return baseRenderer.getSpaceControlled(
        baseRenderer.trim(baseRenderer.getSpaceCollapsedText(node.nodeValue)),
        node,
      );
    },
    /*
     * This converter overwrites the default indented list converter
     * to allow us to parameterize the number of indent spaces for
     * sublists.
     *
     * See the original implementation in
     * https://github.com/nhn/tui.editor/blob/master/libs/to-mark/src/renderer.basic.js#L161
     */
    [sublistNode](node, subContent) {
      const baseResult = baseRenderer.convert(node, subContent);
      // Default to 1 to prevent possible divide by 0
      const firstLevelIndentSpacesCount = countIndentSpaces(baseResult) || 1;
      const reindentedList = baseResult
        .split('\n')
        .map(line => {
          const itemIndentSpacesCount = countIndentSpaces(line);
          const nestingLevel = Math.ceil(itemIndentSpacesCount / firstLevelIndentSpacesCount);
          const indentSpaces = repeat(' ', subListIndentSpaces * nestingLevel);

          return line.replace(/^ +/, indentSpaces);
        })
        .join('\n');

      return reindentedList;
    },
  };
};

export default buildHTMLToMarkdownRender;
