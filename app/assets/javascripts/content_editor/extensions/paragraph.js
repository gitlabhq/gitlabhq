import Paragraph from '@tiptap/extension-paragraph';

export default Paragraph.extend({
  addOptions() {
    return {
      ...this.parent?.(),
      HTMLAttributes: {
        dir: 'auto',
      },
    };
  },
});
