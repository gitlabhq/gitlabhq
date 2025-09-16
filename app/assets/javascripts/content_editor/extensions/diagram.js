import { lowlight } from 'lowlight/lib/core';
import { textblockTypeInputRule } from '@tiptap/core';
import { Fragment } from '@tiptap/pm/model';
import { base64DecodeUnicode } from '~/lib/utils/text_utility';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';
import languageLoader from '../services/code_block_language_loader';
import CodeBlockHighlight from './code_block_highlight';

const backtickInputRegex = /^```(mermaid|plantuml)[\s\n]$/;

export const DEFAULT_MERMAID_CONTENT = 'graph TD;\n    A-->B;\n    A-->C;\n    B-->D;\n    C-->D;';
export const DEFAULT_PLANTUML_CONTENT =
  '@startuml\nAlice -> Bob: Authentication Request\nBob --> Alice: Authentication Response\n@enduml';

export default CodeBlockHighlight.extend({
  name: 'diagram',

  isolating: true,

  addOptions() {
    return {
      lowlight,
    };
  },

  addAttributes() {
    return {
      language: {
        default: null,
        parseHTML: (element) => {
          return element.dataset.diagram;
        },
      },
      isDiagram: {
        default: true,
      },
      showPreview: {
        default: true,
      },
    };
  },

  parseHTML() {
    return [
      {
        priority: PARSE_HTML_PRIORITY_HIGHEST,
        tag: 'pre[data-canonical-lang="mermaid"]',
        getAttrs: () => ({ language: 'mermaid' }),
      },
      {
        priority: PARSE_HTML_PRIORITY_HIGHEST,
        tag: '[data-diagram]',
        getContent(element, schema) {
          const source = base64DecodeUnicode(
            element.dataset.diagramSrc.replace('data:text/plain;base64,', ''),
          );
          return Fragment.from(schema.text(source));
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
    return {
      insertMermaid:
        () =>
        ({ commands }) => {
          return commands.insertContent({
            type: this.type.name,
            attrs: {
              language: 'mermaid',
            },
            content: [
              {
                type: 'text',
                text: DEFAULT_MERMAID_CONTENT,
              },
            ],
          });
        },
      insertPlantUML:
        () =>
        ({ commands }) => {
          return commands.insertContent({
            type: this.type.name,
            attrs: {
              language: 'plantuml',
            },
            content: [
              {
                type: 'text',
                text: DEFAULT_PLANTUML_CONTENT,
              },
            ],
          });
        },
    };
  },

  addInputRules() {
    const getAttributes = (match) => languageLoader?.loadLanguageFromInputRule(match) || {};

    return [
      textblockTypeInputRule({
        find: backtickInputRegex,
        type: this.type,
        getAttributes,
      }),
    ];
  },
});
