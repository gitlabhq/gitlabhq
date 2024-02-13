import { Strike } from '@tiptap/extension-strike';

export default Strike.extend({
  addAttributes() {
    return {
      ...this.parent?.(),

      htmlTag: {
        default: null,
        renderHTML: () => '',
      },
    };
  },

  parseHTML() {
    return [
      { tag: 'del' },
      { tag: 's', attrs: { htmlTag: 's' } },
      { tag: 'strike', attrs: { htmlTag: 'strike' } },
    ];
  },
});
