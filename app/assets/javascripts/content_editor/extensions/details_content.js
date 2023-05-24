import { Node, mergeAttributes } from '@tiptap/core';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';

export default Node.create({
  name: 'detailsContent',
  content: 'block+',
  defining: true,

  addOptions() {
    return {
      HTMLAttributes: {
        dir: 'auto',
      },
    };
  },

  parseHTML() {
    return [
      { tag: '*', consuming: false, context: 'details/', priority: PARSE_HTML_PRIORITY_HIGHEST },
    ];
  },

  renderHTML({ HTMLAttributes }) {
    return ['li', mergeAttributes(this.options.HTMLAttributes, HTMLAttributes), 0];
  },

  addKeyboardShortcuts() {
    return {
      Enter: () => {
        if (!this.editor.isActive('detailsContent')) return false;

        return this.editor.commands.splitListItem('detailsContent');
      },
      'Shift-Tab': () => {
        if (!this.editor.isActive('detailsContent')) return false;

        return this.editor.commands.liftListItem('detailsContent');
      },
    };
  },
});
