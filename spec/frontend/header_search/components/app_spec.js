import { GlSearchBoxByType } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import HeaderSearchApp from '~/header_search/components/app.vue';

describe('HeaderSearchApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(HeaderSearchApp);
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findHeaderSearchInput = () => wrapper.findComponent(GlSearchBoxByType);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders Header Search Input always', () => {
      expect(findHeaderSearchInput().exists()).toBe(true);
    });
  });
});
