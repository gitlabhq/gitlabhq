import renderer from '~/static_site_editor/rich_content_editor/services/renderers/render_list_item';
import * as renderUtils from '~/static_site_editor/rich_content_editor/services/renderers/render_utils';

describe('rich_content_editor/renderers/render_list_item', () => {
  it('canRender delegates to renderUtils.willAlwaysRender', () => {
    expect(renderer.canRender).toBe(renderUtils.willAlwaysRender);
  });

  it('render delegates to renderUtils.renderWithAttributeDefinitions', () => {
    expect(renderer.render).toBe(renderUtils.renderWithAttributeDefinitions);
  });
});
