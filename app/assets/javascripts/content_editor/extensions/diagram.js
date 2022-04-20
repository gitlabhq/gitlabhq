import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';
import CodeBlockHighlight from './code_block_highlight';

export default CodeBlockHighlight.extend({
  name: 'diagram',

  isolating: true,

  addAttributes() {
    return {
      language: {
        default: null,
        parseHTML: (element) => {
          return element.dataset.diagram;
        },
      },
    };
  },

  parseHTML() {
    return [
      {
        priority: PARSE_HTML_PRIORITY_HIGHEST,
        tag: '[data-diagram]',
        getContent(element, schema) {
          const source = atob(element.dataset.diagramSrc.replace('data:text/plain;base64,', ''));
          const node = schema.node('paragraph', {}, [schema.text(source)]);
          return node.content;
        },
      },
    ];
  },

  renderHTML({ HTMLAttributes: { language, ...HTMLAttributes } }) {
    return [
      'div',
      [
        'pre',
        {
          language,
          class: `content-editor-code-block code highlight`,
          ...HTMLAttributes,
        },
        ['code', {}, 0],
      ],
    ];
  },

  addCommands() {
    return {};
  },

  addInputRules() {
    return [];
  },
});
