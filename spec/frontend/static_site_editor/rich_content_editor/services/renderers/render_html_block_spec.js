import { buildUneditableHtmlAsTextTokens } from '~/static_site_editor/rich_content_editor/services/renderers/build_uneditable_token';
import renderer from '~/static_site_editor/rich_content_editor/services/renderers/render_html_block';

describe('rich_content_editor/services/renderers/render_html_block', () => {
  const htmlBlockNode = {
    literal: '<div><h1>Heading</h1><p>Paragraph.</p></div>',
    type: 'htmlBlock',
  };

  describe('canRender', () => {
    it.each`
      input                                                                                | result
      ${htmlBlockNode}                                                                     | ${true}
      ${{ literal: '<iframe></iframe>', type: 'htmlBlock' }}                               | ${true}
      ${{ literal: '<iframe src="https://www.youtube.com"></iframe>', type: 'htmlBlock' }} | ${false}
      ${{ literal: '<iframe></iframe>', type: 'text' }}                                    | ${false}
    `('returns $result when input=$input', ({ input, result }) => {
      expect(renderer.canRender(input)).toBe(result);
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
