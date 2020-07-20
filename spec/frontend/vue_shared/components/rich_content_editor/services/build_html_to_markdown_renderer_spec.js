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

  describe('UL LI visitor', () => {
    it.each`
      listItem           | unorderedListBulletChar | result             | bulletChar
      ${'* list item'}   | ${undefined}            | ${'- list item'}   | ${'default'}
      ${'  - list item'} | ${'*'}                  | ${'  * list item'} | ${'*'}
      ${'  * list item'} | ${'-'}                  | ${'  - list item'} | ${'-'}
    `(
      'uses $bulletChar bullet char in unordered list items when $unorderedListBulletChar is set in config',
      ({ listItem, unorderedListBulletChar, result }) => {
        htmlToMarkdownRenderer = buildHTMLToMarkdownRenderer(baseRenderer, {
          unorderedListBulletChar,
        });
        baseRenderer.convert.mockReturnValueOnce(listItem);

        expect(htmlToMarkdownRenderer['UL LI'](NODE, listItem)).toBe(result);
        expect(baseRenderer.convert).toHaveBeenCalledWith(NODE, listItem);
      },
    );
  });

  describe('OL LI visitor', () => {
    it.each`
      listItem            | result              | incrementListMarker | action
      ${'2. list item'}   | ${'1. list item'}   | ${false}            | ${'increments'}
      ${'  3. list item'} | ${'  1. list item'} | ${false}            | ${'increments'}
      ${'3. list item'}   | ${'3. list item'}   | ${true}             | ${'does not increment'}
    `(
      '$action a list item counter when incrementListMaker is $incrementListMarker',
      ({ listItem, result, incrementListMarker }) => {
        const subContent = null;

        htmlToMarkdownRenderer = buildHTMLToMarkdownRenderer(baseRenderer, {
          incrementListMarker,
        });
        baseRenderer.convert.mockReturnValueOnce(listItem);

        expect(htmlToMarkdownRenderer['OL LI'](NODE, subContent)).toBe(result);
        expect(baseRenderer.convert).toHaveBeenCalledWith(NODE, subContent);
      },
    );
  });

  describe('STRONG, B visitor', () => {
    it.each`
      input                | strongCharacter | result
      ${'**strong text**'} | ${'_'}          | ${'__strong text__'}
      ${'__strong text__'} | ${'*'}          | ${'**strong text**'}
    `(
      'converts $input to $result when strong character is $strongCharacter',
      ({ input, strongCharacter, result }) => {
        htmlToMarkdownRenderer = buildHTMLToMarkdownRenderer(baseRenderer, {
          strong: strongCharacter,
        });

        baseRenderer.convert.mockReturnValueOnce(input);

        expect(htmlToMarkdownRenderer['STRONG, B'](NODE, input)).toBe(result);
        expect(baseRenderer.convert).toHaveBeenCalledWith(NODE, input);
      },
    );
  });

  describe('EM, I visitor', () => {
    it.each`
      input              | emphasisCharacter | result
      ${'*strong text*'} | ${'_'}            | ${'_strong text_'}
      ${'_strong text_'} | ${'*'}            | ${'*strong text*'}
    `(
      'converts $input to $result when emphasis character is $emphasisCharacter',
      ({ input, emphasisCharacter, result }) => {
        htmlToMarkdownRenderer = buildHTMLToMarkdownRenderer(baseRenderer, {
          emphasis: emphasisCharacter,
        });

        baseRenderer.convert.mockReturnValueOnce(input);

        expect(htmlToMarkdownRenderer['EM, I'](NODE, input)).toBe(result);
        expect(baseRenderer.convert).toHaveBeenCalledWith(NODE, input);
      },
    );
  });
});
