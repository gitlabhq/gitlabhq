import { shallowMount } from '@vue/test-utils';
import SpaRoot from '~/vue_shared/spa/components/spa_root.vue';

describe('SpaRoot', () => {
  let wrapper;

  const findRouterView = () => wrapper.find('router-view-stub');
  const findRootDiv = () => wrapper.find('#single-page-app');

  const createWrapper = (props = {}) => {
    wrapper = shallowMount(SpaRoot, {
      propsData: { ...props },
      stubs: ['router-view'],
    });
  };

  describe('template structure', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders root div with correct id', () => {
      expect(findRootDiv().exists()).toBe(true);
    });

    it('renders router-view component', () => {
      expect(findRouterView().exists()).toBe(true);
    });
  });
});
