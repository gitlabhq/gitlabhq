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

  addKeyboardShortcuts() {
    return {
      'Shift-Enter': async () => {
        // can only delegate one shortcut to another async
        await Promise.resolve();
        this.editor.commands.enter();
      },
    };
  },
});
