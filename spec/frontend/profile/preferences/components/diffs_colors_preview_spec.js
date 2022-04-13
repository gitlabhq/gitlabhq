import { shallowMount } from '@vue/test-utils';
import DiffsColorsPreview from '~/profile/preferences/components/diffs_colors_preview.vue';

describe('DiffsColorsPreview component', () => {
  let wrapper;

  function createComponent() {
    wrapper = shallowMount(DiffsColorsPreview);
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders diff colors preview', () => {
    expect(wrapper.element).toMatchSnapshot();
  });
});
