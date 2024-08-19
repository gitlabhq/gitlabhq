import { mergeAttributes, Node } from '@tiptap/core';

export default Node.create({
  name: 'footnotesSection',

  content: 'footnoteDefinition+',

  group: 'block',

  isolating: true,

  addOptions() {
    return {
      HTMLAttributes: {
        dir: 'auto',
      },
    };
  },

  parseHTML() {
    return [
      { tag: 'section.footnotes', skip: true },
      { tag: 'section.footnotes > ol', skip: true },
    ];
  },

  renderHTML({ HTMLAttributes }) {
    return [
      'ol',
      mergeAttributes(this.options.HTMLAttributes, HTMLAttributes, {
        class: 'footnotes gl-text-sm',
      }),
      0,
    ];
  },
});
