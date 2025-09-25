import { shallowMount } from '@vue/test-utils';
import SpaRoot from '~/vue_shared/spa/components/spa_root.vue';

describe('SpaRoot', () => {
  let wrapper;

  const DummyRouteComponent = {
    name: 'DummyRouteComponent',
    template: '<div></div>',
  };

  const DummyRouterView = {
    name: 'DummyRouterView',
    render() {
      return this.$scopedSlots.default({ Component: DummyRouteComponent });
    },
  };

  const findRouterView = () => wrapper.findComponent(DummyRouterView);
  const findRootDiv = () => wrapper.find('#single-page-app');

  const createWrapper = (props = {}) => {
    wrapper = shallowMount(SpaRoot, {
      propsData: { ...props },
      stubs: {
        'router-view': DummyRouterView,
      },
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

    it('renders router-view with scoped slot structure', () => {
      expect(wrapper.findComponent(DummyRouteComponent).exists()).toBe(true);
    });
  });
});
