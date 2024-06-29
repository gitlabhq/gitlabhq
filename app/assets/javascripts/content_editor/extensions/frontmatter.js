import { lowlight } from 'lowlight/lib/core';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';
import CodeBlockHighlight from './code_block_highlight';

export default CodeBlockHighlight.extend({
  name: 'frontmatter',

  addOptions() {
    return {
      lowlight,
    };
  },

  addAttributes() {
    return {
      ...this.parent?.(),
      isFrontmatter: {
        default: true,
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'pre[data-lang-params="frontmatter"]',
        preserveWhitespace: 'full',
        priority: PARSE_HTML_PRIORITY_HIGHEST,
      },
    ];
  },
  addCommands() {
    return {
      setFrontmatter:
        (attributes) =>
        ({ commands }) => {
          return commands.setNode(this.name, attributes);
        },
      toggleFrontmatter:
        (attributes) =>
        ({ commands }) => {
          return commands.toggleNode(this.name, 'paragraph', attributes);
        },
    };
  },

  addInputRules() {
    return [];
  },
});
