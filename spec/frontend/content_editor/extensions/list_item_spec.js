import ListItem from '~/content_editor/extensions/list_item';

describe('content_editor/extensions/list_item', () => {
  it('sets the draggable option to true', () => {
    expect(ListItem.config.draggable).toBe(true);
  });
});
