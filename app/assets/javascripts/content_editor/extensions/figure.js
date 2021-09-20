import { Node } from '@tiptap/core';

export default Node.create({
  name: 'figure',
  content: 'block+',
  group: 'block',
  defining: true,

  parseHTML() {
    return [{ tag: 'figure' }];
  },

  renderHTML({ HTMLAttributes }) {
    return ['figure', HTMLAttributes, 0];
  },
});
