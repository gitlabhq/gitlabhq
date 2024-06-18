import Playable from '~/content_editor/extensions/playable';

describe('content_editor/extensions/playable', () => {
  it('sets the draggable option to true', () => {
    expect(Playable.config.draggable).toBe(true);
  });
});
