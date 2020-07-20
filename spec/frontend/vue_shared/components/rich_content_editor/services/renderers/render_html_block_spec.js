import renderer from '~/vue_shared/components/rich_content_editor/services/renderers/render_html_block';
import { buildUneditableHtmlAsTextTokens } from '~/vue_shared/components/rich_content_editor/services/renderers/build_uneditable_token';

import { normalTextNode } from './mock_data';

const htmlBlockNode = {
  firstChild: null,
  literal: '<div><h1>Heading</h1><p>Paragraph.</p></div>',
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
    const htmlBlockNodeToMark = {
      firstChild: null,
      literal: '<div data-to-mark ></div>',
      type: 'htmlBlock',
    };

    it.each`
      node
      ${htmlBlockNode}
      ${htmlBlockNodeToMark}
    `('should return uneditable tokens wrapping the $node as a token', ({ node }) => {
      expect(renderer.render(node)).toStrictEqual(buildUneditableHtmlAsTextTokens(node));
    });
  });
});
