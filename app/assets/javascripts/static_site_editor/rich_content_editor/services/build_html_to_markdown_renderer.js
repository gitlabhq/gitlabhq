/* eslint-disable @gitlab/require-i18n-strings */
import { defaults, repeat } from 'lodash';

const DEFAULTS = {
  subListIndentSpaces: 4,
  unorderedListBulletChar: '-',
  incrementListMarker: false,
  strong: '*',
  emphasis: '_',
};

const countIndentSpaces = (text) => {
  const matches = text.match(/^\s+/m);

  return matches ? matches[0].length : 0;
};

const buildHTMLToMarkdownRender = (baseRenderer, formattingPreferences = {}) => {
  const {
    subListIndentSpaces,
    unorderedListBulletChar,
    incrementListMarker,
    strong,
    emphasis,
  } = defaults(formattingPreferences, DEFAULTS);
  const sublistNode = 'LI OL, LI UL';
  const unorderedListItemNode = 'UL LI';
  const orderedListItemNode = 'OL LI';
  const emphasisNode = 'EM, I';
  const strongNode = 'STRONG, B';
  const headingNode = 'H1, H2, H3, H4, H5, H6';
  const preCodeNode = 'PRE CODE';

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
        .map((line) => {
          const itemIndentSpacesCount = countIndentSpaces(line);
          const nestingLevel = Math.ceil(itemIndentSpacesCount / firstLevelIndentSpacesCount);
          const indentSpaces = repeat(' ', subListIndentSpaces * nestingLevel);

          return line.replace(/^ +/, indentSpaces);
        })
        .join('\n');

      return reindentedList;
    },
    [unorderedListItemNode](node, subContent) {
      const baseResult = baseRenderer.convert(node, subContent);
      const formatted = baseResult.replace(/^(\s*)([*|-])/, `$1${unorderedListBulletChar}`);
      const { attributeDefinition } = node.dataset;

      return attributeDefinition ? `${formatted.trimRight()}\n${attributeDefinition}\n` : formatted;
    },
    [orderedListItemNode](node, subContent) {
      const baseResult = baseRenderer.convert(node, subContent);

      return incrementListMarker ? baseResult : baseResult.replace(/^(\s*)\d+?\./, '$11.');
    },
    [emphasisNode](node, subContent) {
      const result = baseRenderer.convert(node, subContent);

      return result.replace(/(^[*_]{1}|[*_]{1}$)/g, emphasis);
    },
    [strongNode](node, subContent) {
      const result = baseRenderer.convert(node, subContent);
      const strongSyntax = repeat(strong, 2);

      return result.replace(/^[*_]{2}/, strongSyntax).replace(/[*_]{2}$/, strongSyntax);
    },
    [headingNode](node, subContent) {
      const result = baseRenderer.convert(node, subContent);
      const { attributeDefinition } = node.dataset;

      return attributeDefinition ? `${result.trimRight()}\n${attributeDefinition}\n\n` : result;
    },
    [preCodeNode](node, subContent) {
      const isReferenceDefinition = Boolean(node.dataset.sseReferenceDefinition);

      return isReferenceDefinition
        ? `\n\n${node.innerText}\n\n`
        : baseRenderer.convert(node, subContent);
    },
    IMG(node) {
      const { originalSrc } = node.dataset;
      return `![${node.alt}](${originalSrc || node.src})`;
    },
  };
};

export default buildHTMLToMarkdownRender;
