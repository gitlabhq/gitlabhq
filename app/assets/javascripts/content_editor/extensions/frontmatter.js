import { VueNodeViewRenderer } from '@tiptap/vue-2';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';
import FrontmatterWrapper from '../components/wrappers/frontmatter.vue';
import CodeBlockHighlight from './code_block_highlight';

export default CodeBlockHighlight.extend({
  name: 'frontmatter',
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
      setFrontmatter: (attributes) => ({ commands }) => {
        return commands.setNode(this.name, attributes);
      },
      toggleFrontmatter: (attributes) => ({ commands }) => {
        return commands.toggleNode(this.name, 'paragraph', attributes);
      },
    };
  },
  addNodeView() {
    return new VueNodeViewRenderer(FrontmatterWrapper);
  },

  addInputRules() {
    return [];
  },
});
