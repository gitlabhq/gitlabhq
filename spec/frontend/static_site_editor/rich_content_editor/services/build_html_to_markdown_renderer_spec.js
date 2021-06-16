import buildHTMLToMarkdownRenderer from '~/static_site_editor/rich_content_editor/services/build_html_to_markdown_renderer';
import { attributeDefinition } from './renderers/mock_data';

describe('rich_content_editor/services/html_to_markdown_renderer', () => {
  let baseRenderer;
  let htmlToMarkdownRenderer;
  let fakeNode;

  beforeEach(() => {
    baseRenderer = {
      trim: jest.fn((input) => `trimmed ${input}`),
      getSpaceCollapsedText: jest.fn((input) => `space collapsed ${input}`),
      getSpaceControlled: jest.fn((input) => `space controlled ${input}`),
      convert: jest.fn(),
    };

    fakeNode = { nodeValue: 'mock_node', dataset: {} };
  });

  afterEach(() => {
    htmlToMarkdownRenderer = null;
  });

  describe('TEXT_NODE visitor', () => {
    it('composes getSpaceControlled, getSpaceCollapsedText, and trim services', () => {
      htmlToMarkdownRenderer = buildHTMLToMarkdownRenderer(baseRenderer);

      expect(htmlToMarkdownRenderer.TEXT_NODE(fakeNode)).toBe(
        `space controlled trimmed space collapsed ${fakeNode.nodeValue}`,
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

      expect(htmlToMarkdownRenderer['LI OL, LI UL'](fakeNode, list)).toBe(result);
      expect(baseRenderer.convert).toHaveBeenCalledWith(fakeNode, list);
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

        expect(htmlToMarkdownRenderer['UL LI'](fakeNode, listItem)).toBe(result);
        expect(baseRenderer.convert).toHaveBeenCalledWith(fakeNode, listItem);
      },
    );

    it('detects attribute definitions and attaches them to the list item', () => {
      const listItem = '- list item';
      const result = `${listItem}\n${attributeDefinition}\n`;

      fakeNode.dataset.attributeDefinition = attributeDefinition;
      htmlToMarkdownRenderer = buildHTMLToMarkdownRenderer(baseRenderer);
      baseRenderer.convert.mockReturnValueOnce(`${listItem}\n`);

      expect(htmlToMarkdownRenderer['UL LI'](fakeNode, listItem)).toBe(result);
    });
  });

  describe('OL LI visitor', () => {
    it.each`
      listItem              | result              | incrementListMarker | action
      ${'2. list item'}     | ${'1. list item'}   | ${false}            | ${'increments'}
      ${'  3. list item'}   | ${'  1. list item'} | ${false}            | ${'increments'}
      ${'  123. list item'} | ${'  1. list item'} | ${false}            | ${'increments'}
      ${'3. list item'}     | ${'3. list item'}   | ${true}             | ${'does not increment'}
    `(
      '$action a list item counter when incrementListMaker is $incrementListMarker',
      ({ listItem, result, incrementListMarker }) => {
        const subContent = null;

        htmlToMarkdownRenderer = buildHTMLToMarkdownRenderer(baseRenderer, {
          incrementListMarker,
        });
        baseRenderer.convert.mockReturnValueOnce(listItem);

        expect(htmlToMarkdownRenderer['OL LI'](fakeNode, subContent)).toBe(result);
        expect(baseRenderer.convert).toHaveBeenCalledWith(fakeNode, subContent);
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

        expect(htmlToMarkdownRenderer['STRONG, B'](fakeNode, input)).toBe(result);
        expect(baseRenderer.convert).toHaveBeenCalledWith(fakeNode, input);
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

        expect(htmlToMarkdownRenderer['EM, I'](fakeNode, input)).toBe(result);
        expect(baseRenderer.convert).toHaveBeenCalledWith(fakeNode, input);
      },
    );
  });

  describe('H1, H2, H3, H4, H5, H6 visitor', () => {
    it('detects attribute definitions and attaches them to the heading', () => {
      const heading = 'heading text';
      const result = `${heading.trimRight()}\n${attributeDefinition}\n\n`;

      fakeNode.dataset.attributeDefinition = attributeDefinition;
      htmlToMarkdownRenderer = buildHTMLToMarkdownRenderer(baseRenderer);
      baseRenderer.convert.mockReturnValueOnce(`${heading}\n\n`);

      expect(htmlToMarkdownRenderer['H1, H2, H3, H4, H5, H6'](fakeNode, heading)).toBe(result);
    });
  });

  describe('PRE CODE', () => {
    let node;
    const subContent = 'sub content';
    const originalConverterResult = 'base result';

    beforeEach(() => {
      node = document.createElement('PRE');

      node.innerText = 'reference definition content';
      node.dataset.sseReferenceDefinition = true;

      baseRenderer.convert.mockReturnValueOnce(originalConverterResult);
      htmlToMarkdownRenderer = buildHTMLToMarkdownRenderer(baseRenderer);
    });

    it('returns raw text when pre node has sse-reference-definitions class', () => {
      expect(htmlToMarkdownRenderer['PRE CODE'](node, subContent)).toBe(
        `\n\n${node.innerText}\n\n`,
      );
    });

    it('returns base result when pre node does not have sse-reference-definitions class', () => {
      delete node.dataset.sseReferenceDefinition;

      expect(htmlToMarkdownRenderer['PRE CODE'](node, subContent)).toBe(originalConverterResult);
    });
  });

  describe('IMG', () => {
    const originalSrc = 'path/to/image.png';
    const alt = 'alt text';
    let node;

    beforeEach(() => {
      node = document.createElement('img');
      node.alt = alt;
      node.src = originalSrc;
    });

    it('returns an image with its original src of the `original-src` attribute is preset', () => {
      node.dataset.originalSrc = originalSrc;
      node.src = 'modified/path/to/image.png';

      htmlToMarkdownRenderer = buildHTMLToMarkdownRenderer(baseRenderer);

      expect(htmlToMarkdownRenderer.IMG(node)).toBe(`![${alt}](${originalSrc})`);
    });

    it('fallback to `src` if no `original-src` is specified on the image', () => {
      htmlToMarkdownRenderer = buildHTMLToMarkdownRenderer(baseRenderer);
      expect(htmlToMarkdownRenderer.IMG(node)).toBe(`![${alt}](${originalSrc})`);
    });
  });
});
