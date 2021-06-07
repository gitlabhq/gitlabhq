import {
  buildUneditableBlockTokens,
  buildUneditableOpenTokens,
} from '~/static_site_editor/rich_content_editor/services/renderers/build_uneditable_token';
import {
  renderUneditableLeaf,
  renderUneditableBranch,
  renderWithAttributeDefinitions,
  willAlwaysRender,
} from '~/static_site_editor/rich_content_editor/services/renderers/render_utils';

import { originToken, uneditableCloseToken, attributeDefinition } from './mock_data';

describe('rich_content_editor/renderers/render_utils', () => {
  describe('renderUneditableLeaf', () => {
    it('should return uneditable block tokens around an origin token', () => {
      const context = { origin: jest.fn().mockReturnValueOnce(originToken) };
      const result = renderUneditableLeaf({}, context);

      expect(result).toStrictEqual(buildUneditableBlockTokens(originToken));
    });
  });

  describe('renderUneditableBranch', () => {
    let origin;

    beforeEach(() => {
      origin = jest.fn().mockReturnValueOnce(originToken);
    });

    it('should return uneditable block open token followed by the origin token when entering', () => {
      const context = { entering: true, origin };
      const result = renderUneditableBranch({}, context);

      expect(result).toStrictEqual(buildUneditableOpenTokens(originToken));
    });

    it('should return uneditable block closing token when exiting', () => {
      const context = { entering: false, origin };
      const result = renderUneditableBranch({}, context);

      expect(result).toStrictEqual(uneditableCloseToken);
    });
  });

  describe('willAlwaysRender', () => {
    it('always returns true', () => {
      expect(willAlwaysRender()).toBe(true);
    });
  });

  describe('renderWithAttributeDefinitions', () => {
    let openTagToken;
    let closeTagToken;
    let node;
    const attributes = {
      'data-attribute-definition': attributeDefinition,
    };

    beforeEach(() => {
      openTagToken = { type: 'openTag' };
      closeTagToken = { type: 'closeTag' };
      node = {
        next: {
          firstChild: {
            literal: attributeDefinition,
          },
        },
      };
    });

    describe('when token type is openTag', () => {
      it('attaches attributes when attributes exist in the node’s next sibling', () => {
        const context = { origin: () => openTagToken };

        expect(renderWithAttributeDefinitions(node, context)).toEqual({
          ...openTagToken,
          attributes,
        });
      });

      it('attaches attributes when attributes exist in the node’s children', () => {
        const context = { origin: () => openTagToken };
        node = {
          firstChild: {
            firstChild: {
              next: {
                next: {
                  literal: attributeDefinition,
                },
              },
            },
          },
        };

        expect(renderWithAttributeDefinitions(node, context)).toEqual({
          ...openTagToken,
          attributes,
        });
      });
    });

    it('does not attach attributes when token type is "closeTag"', () => {
      const context = { origin: () => closeTagToken };

      expect(renderWithAttributeDefinitions({}, context)).toBe(closeTagToken);
    });
  });
});
