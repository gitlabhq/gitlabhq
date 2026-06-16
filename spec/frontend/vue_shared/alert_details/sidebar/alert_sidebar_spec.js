import { shallowMount, mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import AlertSidebar from '~/vue_shared/alert_details/components/alert_sidebar.vue';
import SidebarAssignees from '~/vue_shared/alert_details/components/sidebar/sidebar_assignees.vue';
import SidebarStatus from '~/vue_shared/alert_details/components/sidebar/sidebar_status.vue';
import mockAlerts from '../mocks/alerts.json';

const mockAlert = mockAlerts[0];

describe('Alert Details Sidebar', () => {
  let wrapper;
  let mock;

  function createComponent({
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

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  it('should render side bar assignee dropdown', () => {
    createComponent({
      mountMethod: mount,
      alert: mockAlert,
    });
    expect(wrapper.findComponent(SidebarAssignees).exists()).toBe(true);
  });

  it('should render side bar status dropdown', () => {
    createComponent({
      mountMethod: mount,
      alert: mockAlert,
    });
    expect(wrapper.findComponent(SidebarStatus).exists()).toBe(true);
  });
});
