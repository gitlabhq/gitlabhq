import { Node, mergeAttributes } from '@tiptap/core';

export default Node.create({
  name: 'figureCaption',
  content: 'inline*',
  group: 'block',
  defining: true,

  addOptions() {
    return {
      HTMLAttributes: {
        dir: 'auto',
      },
    };
  },

  parseHTML() {
    return [{ tag: 'figcaption' }];
  },

  renderHTML({ HTMLAttributes }) {
    return ['figcaption', mergeAttributes(this.options.HTMLAttributes, HTMLAttributes), 0];
  },
});
