import ListItem from '@tiptap/extension-list-item';

export default ListItem.extend({
  addOptions() {
    return {
      ...this.parent?.(),
      HTMLAttributes: {
        dir: 'auto',
      },
    };
  },
});
