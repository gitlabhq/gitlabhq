import { shallowMount } from '@vue/test-utils';
import BridgeApp from '~/jobs/bridge/app.vue';
import BridgeEmptyState from '~/jobs/bridge/components/empty_state.vue';
import BridgeSidebar from '~/jobs/bridge/components/sidebar.vue';

describe('Bridge Show Page', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(BridgeApp, {});
  };

  const findEmptyState = () => wrapper.findComponent(BridgeEmptyState);
  const findSidebar = () => wrapper.findComponent(BridgeSidebar);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
    });

    it('renders sidebar', () => {
      expect(findSidebar().exists()).toBe(true);
    });
  });
});
