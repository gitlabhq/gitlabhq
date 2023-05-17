import { shallowMount, mount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import AlertSidebar from '~/vue_shared/alert_details/components/alert_sidebar.vue';
import SidebarAssignees from '~/vue_shared/alert_details/components/sidebar/sidebar_assignees.vue';
import SidebarStatus from '~/vue_shared/alert_details/components/sidebar/sidebar_status.vue';
import mockAlerts from '../mocks/alerts.json';

const mockAlert = mockAlerts[0];

describe('Alert Details Sidebar', () => {
  let wrapper;
  let mock;

  function mountComponent({
    mountMethod = shallowMount,
    stubs = {},
    alert = {},
    provide = {},
  } = {}) {
    wrapper = mountMethod(AlertSidebar, {
      data() {
        return {
          sidebarStatus: false,
        };
      },
      propsData: {
        alert,
      },
      provide: {
        projectPath: 'projectPath',
        projectId: '1',
        ...provide,
      },
      stubs,
      mocks: {
        $apollo: {
          queries: {
            sidebarStatus: {},
          },
        },
      },
    });
  }

  afterEach(() => {
    mock.restore();
  });

  describe('the sidebar renders', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);
      mountComponent();
    });

    it('open as default', () => {
      expect(wrapper.classes('right-sidebar-expanded')).toBe(true);
    });

    it('should render side bar assignee dropdown', () => {
      mountComponent({
        mountMethod: mount,
        alert: mockAlert,
      });
      expect(wrapper.findComponent(SidebarAssignees).exists()).toBe(true);
    });

    it('should render side bar status dropdown', () => {
      mountComponent({
        mountMethod: mount,
        alert: mockAlert,
      });
      expect(wrapper.findComponent(SidebarStatus).exists()).toBe(true);
    });
  });
});
