import { Node } from '@tiptap/core';

export default Node.create({
  name: 'figureCaption',
  content: 'inline*',
  group: 'block',
  defining: true,

  parseHTML() {
    return [{ tag: 'figcaption' }];
  },

  renderHTML({ HTMLAttributes }) {
    return ['figcaption', HTMLAttributes, 0];
  },
});
