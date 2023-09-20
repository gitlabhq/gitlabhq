import { shallowMount } from '@vue/test-utils';

import MarkdownFieldView from '~/vue_shared/components/markdown/field_view.vue';
import { renderGFM } from '~/behaviors/markdown/render_gfm';

jest.mock('~/behaviors/markdown/render_gfm');

describe('Markdown Field View component', () => {
  function createComponent(isLoading = false) {
    shallowMount(MarkdownFieldView, { propsData: { isLoading } });
  }

  it('processes rendering with GFM', () => {
    createComponent();

    expect(renderGFM).toHaveBeenCalledTimes(1);
  });

  describe('watchers', () => {
    it('does not process rendering with GFM if isLoading is true', () => {
      createComponent(true);

      expect(renderGFM).not.toHaveBeenCalled();
    });

    it('processes rendering with GFM when isLoading is updated to `false`', () => {
      createComponent(false);

      expect(renderGFM).toHaveBeenCalledTimes(1);
    });
  });
});
