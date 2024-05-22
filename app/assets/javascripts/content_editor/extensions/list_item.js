import ListItem from '@tiptap/extension-list-item';

export default ListItem.extend({
  draggable: true,

  addOptions() {
    return {
      ...this.parent?.(),
      HTMLAttributes: {
        dir: 'auto',
      },
    };
  },
});
