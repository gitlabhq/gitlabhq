import { Node, mergeAttributes } from '@tiptap/core';

export default Node.create({
  name: 'descriptionItem',
  content: 'block+',
  defining: true,

  addOptions() {
    return {
      HTMLAttributes: {
        dir: 'auto',
      },
    };
  },

  addAttributes() {
    return {
      isTerm: {
        default: true,
        parseHTML: (element) => element.tagName.toLowerCase() === 'dt',
      },
    };
  },

  parseHTML() {
    return [{ tag: 'dt' }, { tag: 'dd' }];
  },

  renderHTML({ HTMLAttributes: { isTerm, ...HTMLAttributes } }) {
    return [
      'li',
      mergeAttributes(this.options.HTMLAttributes, HTMLAttributes, {
        class: isTerm ? 'dl-term' : 'dl-description',
      }),
      0,
    ];
  },

  addKeyboardShortcuts() {
    return {
      Enter: () => {
        if (!this.editor.isActive('descriptionItem')) return false;

        return this.editor.commands.splitListItem('descriptionItem');
      },
      Tab: () => {
        if (!this.editor.isActive('descriptionItem')) return false;

        const { isTerm } = this.editor.getAttributes('descriptionItem');
        if (isTerm)
          return this.editor.commands.updateAttributes('descriptionItem', { isTerm: !isTerm });

        return false;
      },
      'Shift-Tab': () => {
        if (!this.editor.isActive('descriptionItem')) return false;

        const { isTerm } = this.editor.getAttributes('descriptionItem');
        if (isTerm) return this.editor.commands.liftListItem('descriptionItem');

        return this.editor.commands.updateAttributes('descriptionItem', { isTerm: true });
      },
    };
  },
});
