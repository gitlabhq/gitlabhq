import renderer from '~/vue_shared/components/rich_content_editor/services/renderers/render_identifier_paragraph';
import {
  buildUneditableOpenTokens,
  buildUneditableCloseToken,
} from '~/vue_shared/components/rich_content_editor/services/renderers/build_uneditable_token';

import { buildMockParagraphNode, normalParagraphNode } from '../../mock_data';

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
    let origin;

    beforeEach(() => {
      origin = jest.fn();
    });

    it('should return uneditable open tokens when entering', () => {
      const context = { entering: true, origin };

      expect(renderer.render(identifierParagraphNode, context)).toStrictEqual(
        buildUneditableOpenTokens(origin()),
      );
    });

    it('should return an uneditable close tokens when exiting', () => {
      const context = { entering: false, origin };

      expect(renderer.render(identifierParagraphNode, context)).toStrictEqual(
        buildUneditableCloseToken(origin()),
      );
    });
  });
});
