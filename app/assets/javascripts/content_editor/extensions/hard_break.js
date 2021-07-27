import { HardBreak } from '@tiptap/extension-hard-break';

export default HardBreak.extend({
  addKeyboardShortcuts() {
    return {
      'Shift-Enter': () => this.editor.commands.setHardBreak(),
    };
  },
});
