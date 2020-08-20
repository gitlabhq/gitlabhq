import renderer from '~/vue_shared/components/rich_content_editor/services/renderers/render_identifier_paragraph';
import { renderUneditableBranch } from '~/vue_shared/components/rich_content_editor/services/renderers/render_utils';

import { buildMockTextNode } from './mock_data';

const buildMockParagraphNode = literal => {
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

describe('Render Identifier Paragraph renderer', () => {
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
    it('should delegate rendering to the renderUneditableBranch util', () => {
      expect(renderer.render).toBe(renderUneditableBranch);
    });
  });
});
