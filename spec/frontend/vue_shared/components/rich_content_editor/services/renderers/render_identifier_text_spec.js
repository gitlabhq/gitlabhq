import renderer from '~/vue_shared/components/rich_content_editor/services/renderers/render_identifier_text';
import {
  buildUneditableOpenTokens,
  buildUneditableCloseTokens,
  buildUneditableTokens,
} from '~/vue_shared/components/rich_content_editor/services/renderers/build_uneditable_token';

import {
  identifierTextNode,
  identifierInlineCodeTextEnteringNode,
  identifierInlineCodeTextExitingNode,
  normalTextNode,
} from '../../mock_data';

describe('Render Identifier Text renderer', () => {
  describe('canRender', () => {
    it('should return true when the argument `literal` has identifier syntax', () => {
      expect(renderer.canRender(identifierTextNode)).toBe(true);
    });

    it('should return true when the argument `literal` has identifier syntax and forward adjacent inline code', () => {
      expect(renderer.canRender(identifierInlineCodeTextEnteringNode)).toBe(true);
    });

    it('should return true when the argument `literal` has identifier syntax and backward adjacent inline code', () => {
      expect(renderer.canRender(identifierInlineCodeTextExitingNode)).toBe(true);
    });

    it('should return false when the argument `literal` lacks identifier syntax', () => {
      expect(renderer.canRender(normalTextNode)).toBe(false);
    });
  });

  describe('render', () => {
    const origin = jest.fn();

    it('should return uneditable tokens for basic identifier syntax', () => {
      const context = { origin };

      expect(renderer.render(identifierTextNode, context)).toStrictEqual(
        buildUneditableTokens(origin()),
      );
    });

    it('should return uneditable open tokens for non-basic inline code identifier syntax when entering', () => {
      const context = { origin };

      expect(renderer.render(identifierInlineCodeTextEnteringNode, context)).toStrictEqual(
        buildUneditableOpenTokens(origin()),
      );
    });

    it('should return uneditable close tokens for non-basic inline code identifier syntax when exiting', () => {
      const context = { origin };

      expect(renderer.render(identifierInlineCodeTextExitingNode, context)).toStrictEqual(
        buildUneditableCloseTokens(origin()),
      );
    });
  });
});
