import renderer from '~/static_site_editor/rich_content_editor/services/renderers/render_identifier_paragraph';

import { buildMockTextNode } from './mock_data';

const buildMockParagraphNode = (literal) => {
  return {
    firstChild: buildMockTextNode(literal),
    type: 'paragraph',
  };
};

const normalParagraphNode = buildMockParagraphNode(
  'This is just normal paragraph. It has multiple sentences.',
);
const identifierParagraphNode = buildMockParagraphNode(
  `[another-identifier]: https://example.com "This example has a title" [identifier]: http://example1.com [this link]: http://example2.com`,
);

describe('rich_content_editor/renderers_render_identifier_paragraph', () => {
  describe('canRender', () => {
    it.each`
      node                       | paragraph                                          | target
      ${identifierParagraphNode} | ${'[Some text]: https://link.com'}                 | ${true}
      ${normalParagraphNode}     | ${'Normal non-identifier text. Another sentence.'} | ${false}
    `(
      'should return $target when the $node matches $paragraph syntax',
      ({ node, paragraph, target }) => {
        const context = {
          entering: true,
          getChildrenText: jest.fn().mockReturnValueOnce(paragraph),
        };

        expect(renderer.canRender(node, context)).toBe(target);
      },
    );
  });

  describe('render', () => {
    let context;
    let result;

    beforeEach(() => {
      const node = {
        firstChild: {
          type: 'text',
          literal: '[Some text]: https://link.com',
          next: {
            type: 'linebreak',
            next: {
              type: 'text',
              literal: '[identifier]: http://example1.com "title"',
            },
          },
        },
      };
      context = { skipChildren: jest.fn() };
      result = renderer.render(node, context);
    });

    it('renders the reference definitions as a code block', () => {
      expect(result).toEqual([
        {
          type: 'openTag',
          tagName: 'pre',
          classNames: ['code-block', 'language-markdown'],
          attributes: {
            'data-sse-reference-definition': true,
          },
        },
        { type: 'openTag', tagName: 'code' },
        {
          type: 'text',
          content: '[Some text]: https://link.com\n[identifier]: http://example1.com "title"',
        },
        { type: 'closeTag', tagName: 'code' },
        { type: 'closeTag', tagName: 'pre' },
      ]);
    });

    it('skips the reference definition node children from rendering', () => {
      expect(context.skipChildren).toHaveBeenCalled();
    });
  });
});
