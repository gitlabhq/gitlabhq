import { buildUneditableInlineTokens } from '~/static_site_editor/rich_content_editor/services/renderers/build_uneditable_token';
import renderer from '~/static_site_editor/rich_content_editor/services/renderers/render_font_awesome_html_inline';

import { normalTextNode } from './mock_data';

const fontAwesomeInlineHtmlNode = {
  firstChild: null,
  literal: '<i class="far fa-paper-plane" id="biz-tech-icons">',
  type: 'html',
};

describe('Render Font Awesome Inline HTML renderer', () => {
  describe('canRender', () => {
    it('should return true when the argument `literal` has font awesome inline html syntax', () => {
      expect(renderer.canRender(fontAwesomeInlineHtmlNode)).toBe(true);
    });

    it('should return false when the argument `literal` lacks font awesome inline html syntax', () => {
      expect(renderer.canRender(normalTextNode)).toBe(false);
    });
  });

  describe('render', () => {
    it('should return uneditable inline tokens', () => {
      const token = { type: 'text', tagName: null, content: fontAwesomeInlineHtmlNode.literal };
      const context = { origin: () => token };

      expect(renderer.render(fontAwesomeInlineHtmlNode, context)).toStrictEqual(
        buildUneditableInlineTokens(token),
      );
    });
  });
});
