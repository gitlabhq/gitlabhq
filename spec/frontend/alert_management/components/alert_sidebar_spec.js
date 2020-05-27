import { shallowMount } from '@vue/test-utils';
import AlertSidebar from '~/alert_management/components/alert_sidebar.vue';

describe('Alert Details Sidebar', () => {
  let wrapper;

  function mountComponent({
    sidebarCollapsed = true,
    mountMethod = shallowMount,
    stubs = {},
  } = {}) {
    wrapper = mountMethod(AlertSidebar, {
      propsData: {
        alert: {},
        sidebarCollapsed,
        projectPath: 'projectPath',
      },
      stubs,
    });
  }

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  describe('the sidebar renders', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('open as default', () => {
      expect(wrapper.props('sidebarCollapsed')).toBe(true);
    });
  });
});
