import { Mark } from '@tiptap/core';
import { Fragment } from '@tiptap/pm/model';
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

  parseHTML() {
    return [
      {
        tag: 'code',
        preserveWhitespace: true,
        getContent(element, schema) {
          return Fragment.from(schema.text(element.textContent));
        },
      },
    ];
  },

  addKeyboardShortcuts() {
    return {
      ArrowRight: () => {
        return Mark.handleExit({ editor: this.editor, mark: this });
      },
    };
  },

  addCommands() {
    return {
      ...this.parent?.(),
      setCode:
        () =>
        ({ chain }) =>
          chain().unlinkReferencesInSelection().setMark(this.name).run(),
      toggleCode:
        () =>
        ({ chain }) =>
          chain().unlinkReferencesInSelection().toggleMark(this.name).run(),
    };
  },
});
