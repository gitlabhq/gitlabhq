import renderer from '~/static_site_editor/rich_content_editor/services/renderers/render_attribute_definition';
import { attributeDefinition } from './mock_data';

describe('rich_content_editor/renderers/render_attribute_definition', () => {
  describe('canRender', () => {
    it.each`
      input                                       | result
      ${{ literal: attributeDefinition }}         | ${true}
      ${{ literal: `FOO${attributeDefinition}` }} | ${false}
      ${{ literal: `${attributeDefinition}BAR` }} | ${false}
      ${{ literal: 'foobar' }}                    | ${false}
    `('returns $result when input is $input', ({ input, result }) => {
      expect(renderer.canRender(input)).toBe(result);
    });
  });

  describe('render', () => {
    it('returns an empty HTML comment', () => {
      expect(renderer.render()).toEqual({
        type: 'html',
        content: '<!-- sse-attribute-definition -->',
      });
    });
  });
});
