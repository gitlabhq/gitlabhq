import renderer from '~/static_site_editor/rich_content_editor/services/renderers/render_softbreak';

describe('Render softbreak renderer', () => {
  describe('canRender', () => {
    it.each`
      node                                 | parentType     | result
      ${{ parent: { type: 'emph' } }}      | ${'emph'}      | ${true}
      ${{ parent: { type: 'strong' } }}    | ${'strong'}    | ${true}
      ${{ parent: { type: 'paragraph' } }} | ${'paragraph'} | ${false}
    `('returns $result when node parent type is $parentType ', ({ node, result }) => {
      expect(renderer.canRender(node)).toBe(result);
    });
  });

  describe('render', () => {
    it('returns text node with a break line', () => {
      expect(renderer.render()).toEqual({
        type: 'text',
        content: ' ',
      });
    });
  });
});
