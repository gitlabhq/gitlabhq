import { mergeAttributes, Node } from '@tiptap/core';
import { VueNodeViewRenderer } from '@tiptap/vue-2';
import FootnoteDefinitionWrapper from '../components/wrappers/footnote_definition.vue';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';

const extractFootnoteIdentifier = (idAttribute) => /^fn-(\w+)-\d+$/.exec(idAttribute)?.[1];

export default Node.create({
  name: 'footnoteDefinition',
  content: 'paragraph',
  group: 'block',
  isolating: true,
  addAttributes() {
    return {
      identifier: {
        default: null,
        parseHTML: (element) => extractFootnoteIdentifier(element.getAttribute('id')),
      },
      label: {
        default: null,
        parseHTML: (element) => extractFootnoteIdentifier(element.getAttribute('id')),
      },
    };
  },

  parseHTML() {
    return [
      { tag: 'section.footnotes li' },
      { tag: '.footnote-backref', priority: PARSE_HTML_PRIORITY_HIGHEST, ignore: true },
    ];
  },

  renderHTML({ label, ...HTMLAttributes }) {
    return ['div', mergeAttributes(HTMLAttributes), 0];
  },

  addNodeView() {
    return new VueNodeViewRenderer(FootnoteDefinitionWrapper);
  },
});
