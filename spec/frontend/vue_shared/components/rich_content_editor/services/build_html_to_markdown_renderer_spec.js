import buildHTMLToMarkdownRenderer from '~/vue_shared/components/rich_content_editor/services/build_html_to_markdown_renderer';

describe('HTMLToMarkdownRenderer', () => {
  let baseRenderer;
  let htmlToMarkdownRenderer;
  const NODE = { nodeValue: 'mock_node' };

  beforeEach(() => {
    baseRenderer = {
      trim: jest.fn(input => `trimmed ${input}`),
      getSpaceCollapsedText: jest.fn(input => `space collapsed ${input}`),
      getSpaceControlled: jest.fn(input => `space controlled ${input}`),
    };
    htmlToMarkdownRenderer = buildHTMLToMarkdownRenderer(baseRenderer);
  });

  describe('TEXT_NODE visitor', () => {
    it('composes getSpaceControlled, getSpaceCollapsedText, and trim services', () => {
      expect(htmlToMarkdownRenderer.TEXT_NODE(NODE)).toBe(
        `space controlled trimmed space collapsed ${NODE.nodeValue}`,
      );
    });
  });
});
