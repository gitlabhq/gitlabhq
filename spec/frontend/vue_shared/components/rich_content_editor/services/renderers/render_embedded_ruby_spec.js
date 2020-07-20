import renderer from '~/vue_shared/components/rich_content_editor/services/renderers/render_embedded_ruby_text';
import { buildUneditableTokens } from '~/vue_shared/components/rich_content_editor/services/renderers/build_uneditable_token';

import { buildMockTextNode, normalTextNode } from './mock_data';

const embeddedRubyTextNode = buildMockTextNode('<%= partial("some/path") %>');

describe('Render Embedded Ruby Text renderer', () => {
  describe('canRender', () => {
    it('should return true when the argument `literal` has embedded ruby syntax', () => {
      expect(renderer.canRender(embeddedRubyTextNode)).toBe(true);
    });

    it('should return false when the argument `literal` lacks embedded ruby syntax', () => {
      expect(renderer.canRender(normalTextNode)).toBe(false);
    });
  });

  describe('render', () => {
    const origin = jest.fn();

    it('should return uneditable tokens', () => {
      const context = { origin };

      expect(renderer.render(embeddedRubyTextNode, context)).toStrictEqual(
        buildUneditableTokens(origin()),
      );
    });
  });
});
