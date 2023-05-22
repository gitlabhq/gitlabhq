import { Mark } from '@tiptap/core';
import Code from '@tiptap/extension-code';
import { EXTENSION_PRIORITY_LOWER } from '../constants';

export default Code.extend({
  excludes: null,

  /**
   * Reduce the rendering priority of the code mark to
   * ensure the bold, italic, and strikethrough marks
   * are rendered first.
   */
  priority: EXTENSION_PRIORITY_LOWER,

  addKeyboardShortcuts() {
    return {
      ArrowRight: () => {
        return Mark.handleExit({ editor: this.editor, mark: this });
      },
    };
  },
});
