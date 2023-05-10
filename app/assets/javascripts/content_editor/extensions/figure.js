import { Node, mergeAttributes } from '@tiptap/core';

export default Node.create({
  name: 'figure',
  content: 'block+',
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
    return [{ tag: 'figure' }];
  },

  renderHTML({ HTMLAttributes }) {
    return ['figure', mergeAttributes(this.options.HTMLAttributes, HTMLAttributes), 0];
  },
});
