import renderer from '~/vue_shared/components/rich_content_editor/services/renderers/render_kramdown_text';
import { buildUneditableTokens } from '~/vue_shared/components/rich_content_editor/services/renderers/build_uneditable_token';

import { kramdownTextNode, normalTextNode } from '../../mock_data';

describe('Render Kramdown Text renderer', () => {
  describe('canRender', () => {
    it('should return true when the argument `literal` has kramdown syntax', () => {
      expect(renderer.canRender(kramdownTextNode)).toBe(true);
    });

    it('should return false when the argument `literal` lacks kramdown syntax', () => {
      expect(renderer.canRender(normalTextNode)).toBe(false);
    });
  });

  describe('render', () => {
    const origin = jest.fn();

    it('should return uneditable tokens', () => {
      const context = { origin };

      expect(renderer.render(kramdownTextNode, context)).toStrictEqual(
        buildUneditableTokens(origin()),
      );
    });
  });
});
