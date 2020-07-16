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
      convert: jest.fn(),
    };
  });

  describe('TEXT_NODE visitor', () => {
    it('composes getSpaceControlled, getSpaceCollapsedText, and trim services', () => {
      htmlToMarkdownRenderer = buildHTMLToMarkdownRenderer(baseRenderer);

      expect(htmlToMarkdownRenderer.TEXT_NODE(NODE)).toBe(
        `space controlled trimmed space collapsed ${NODE.nodeValue}`,
      );
    });
  });

  describe('LI OL, LI UL visitor', () => {
    const oneLevelNestedList = '\n    * List item 1\n    * List item 2';
    const twoLevelNestedList = '\n  * List item 1\n    * List item 2';
    const spaceInContentList = '\n  * List    item 1\n  * List item 2';

    it.each`
      list                  | indentSpaces | result
      ${oneLevelNestedList} | ${2}         | ${'\n  * List item 1\n  * List item 2'}
      ${oneLevelNestedList} | ${3}         | ${'\n   * List item 1\n   * List item 2'}
      ${oneLevelNestedList} | ${6}         | ${'\n      * List item 1\n      * List item 2'}
      ${twoLevelNestedList} | ${4}         | ${'\n    * List item 1\n        * List item 2'}
      ${spaceInContentList} | ${1}         | ${'\n * List    item 1\n * List item 2'}
    `('changes the list indentation to $indentSpaces spaces', ({ list, indentSpaces, result }) => {
      htmlToMarkdownRenderer = buildHTMLToMarkdownRenderer(baseRenderer, {
        subListIndentSpaces: indentSpaces,
      });

      baseRenderer.convert.mockReturnValueOnce(list);

      expect(htmlToMarkdownRenderer['LI OL, LI UL'](NODE, list)).toBe(result);
      expect(baseRenderer.convert).toHaveBeenCalledWith(NODE, list);
    });
  });
});
