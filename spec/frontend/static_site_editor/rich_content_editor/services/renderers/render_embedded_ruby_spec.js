import renderer from '~/static_site_editor/rich_content_editor/services/renderers/render_embedded_ruby_text';
import { renderUneditableLeaf } from '~/static_site_editor/rich_content_editor/services/renderers/render_utils';

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
    it('should delegate rendering to the renderUneditableLeaf util', () => {
      expect(renderer.render).toBe(renderUneditableLeaf);
    });
  });
});
