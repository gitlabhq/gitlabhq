import { shallowMount, mount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import AlertSidebar from '~/alert_management/components/alert_sidebar.vue';
import SidebarAssignees from '~/alert_management/components/sidebar/sidebar_assignees.vue';
import mockAlerts from '../mocks/alerts.json';

const mockAlert = mockAlerts[0];

describe('Alert Details Sidebar', () => {
  let wrapper;
  let mock;

  function mountComponent({
    sidebarCollapsed = true,
    mountMethod = shallowMount,
    alertAssignee = false,
    stubs = {},
    alert = {},
  } = {}) {
    wrapper = mountMethod(AlertSidebar, {
      propsData: {
        alert,
        sidebarCollapsed,
        projectPath: 'projectPath',
      },
      provide: {
        glFeatures: { alertAssignee },
      },
      stubs,
    });
  }

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
    mock.restore();
  });

  describe('the sidebar renders', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);
      mountComponent();
    });

    it('open as default', () => {
      expect(wrapper.props('sidebarCollapsed')).toBe(true);
    });

    it('should not render side bar assignee dropdown by default', () => {
      expect(wrapper.find(SidebarAssignees).exists()).toBe(false);
    });

    it('should render side bar assignee dropdown if feature flag enabled', () => {
      mountComponent({
        mountMethod: mount,
        alertAssignee: true,
        alert: mockAlert,
      });
      expect(wrapper.find(SidebarAssignees).exists()).toBe(true);
    });
  });
});
