import renderer from '~/vue_shared/components/rich_content_editor/services/renderers/render_html';
import { buildUneditableTokens } from '~/vue_shared/components/rich_content_editor/services/renderers/build_uneditable_token';

import { normalTextNode } from './mock_data';

const htmlLiteral = '<div><h1>Heading</h1><p>Paragraph.</p></div>';
const htmlBlockNode = {
  firstChild: null,
  literal: htmlLiteral,
  type: 'htmlBlock',
};

describe('Render HTML renderer', () => {
  describe('canRender', () => {
    it('should return true when the argument is an html block', () => {
      expect(renderer.canRender(htmlBlockNode)).toBe(true);
    });

    it('should return false when the argument is not an html block', () => {
      expect(renderer.canRender(normalTextNode)).toBe(false);
    });
  });

  describe('render', () => {
    it('should return uneditable tokens wrapping the origin token', () => {
      const origin = jest.fn();
      const context = { origin };

      expect(renderer.render(htmlBlockNode, context)).toStrictEqual(
        buildUneditableTokens(origin()),
      );
    });
  });
});
