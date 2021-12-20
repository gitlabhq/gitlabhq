import { mergeAttributes, Node } from '@tiptap/core';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';

export default Node.create({
  name: 'footnoteDefinition',

  content: 'paragraph',

  group: 'block',

  parseHTML() {
    return [
      { tag: 'section.footnotes li' },
      { tag: '.footnote-backref', priority: PARSE_HTML_PRIORITY_HIGHEST, ignore: true },
    ];
  },

  renderHTML({ HTMLAttributes }) {
    return ['li', mergeAttributes(HTMLAttributes), 0];
  },
});
