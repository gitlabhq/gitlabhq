import { shallowMount } from '@vue/test-utils';

import MarkdownFieldView from '~/vue_shared/components/markdown/field_view.vue';
import { renderGFM } from '~/behaviors/markdown/render_gfm';

jest.mock('~/behaviors/markdown/render_gfm');

describe('Markdown Field View component', () => {
  function createComponent() {
    shallowMount(MarkdownFieldView);
  }

  beforeEach(() => {
    createComponent();
  });

  it('processes rendering with GFM', () => {
    expect(renderGFM).toHaveBeenCalledTimes(1);
  });
});
