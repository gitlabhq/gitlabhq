import { GlDropdown, GlDropdownItem, GlLoadingIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import updateAlertStatusMutation from '~/graphql_shared/mutations/alert_status_update.mutation.graphql';
import AlertStatus from '~/vue_shared/alert_details/components/alert_status.vue';
import AlertSidebarStatus from '~/vue_shared/alert_details/components/sidebar/sidebar_status.vue';
import { PAGE_CONFIG } from '~/vue_shared/alert_details/constants';
import mockAlerts from '../mocks/alerts.json';

const mockAlert = mockAlerts[0];

describe('Alert Details Sidebar Status', () => {
  let wrapper;
  const findStatusDropdown = () => wrapper.find(GlDropdown);
  const findStatusDropdownItem = () => wrapper.find(GlDropdownItem);
  const findStatusLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const findStatusDropdownHeader = () => wrapper.find('[data-testid="dropdown-header"]');
  const findAlertStatus = () => wrapper.findComponent(AlertStatus);
  const findStatus = () => wrapper.find('[data-testid="status"]');

  function mountComponent({
    data,
    sidebarCollapsed = true,
    loading = false,
    stubs = {},
    provide = {},
  } = {}) {
    wrapper = mount(AlertSidebarStatus, {
      propsData: {
        alert: { ...mockAlert },
        ...data,
        sidebarCollapsed,
        projectPath: 'projectPath',
      },
      mocks: {
        $apollo: {
          mutate: jest.fn(),
          queries: {
            alert: {
              loading,
            },
          },
        },
      },
      stubs,
      provide,
    });
  }

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  describe('Alert Sidebar Dropdown Status', () => {
    beforeEach(() => {
      mountComponent({
        data: { alert: mockAlert },
        sidebarCollapsed: false,
        loading: false,
      });
    });

    it('displays status dropdown', () => {
      expect(findStatusDropdown().exists()).toBe(true);
    });

    it('displays the dropdown status header', () => {
      expect(findStatusDropdownHeader().exists()).toBe(true);
    });

    describe('updating the alert status', () => {
      const mockUpdatedMutationResult = {
        data: {
          updateAlertStatus: {
            errors: [],
            alert: {
              status: 'acknowledged',
            },
          },
        },
      };

      beforeEach(() => {
        mountComponent({
          data: { alert: mockAlert },
          sidebarCollapsed: false,
          loading: false,
        });
      });

      it('calls `$apollo.mutate` with `updateAlertStatus` mutation and variables containing `iid`, `status`, & `projectPath`', () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockUpdatedMutationResult);
        findStatusDropdownItem().vm.$emit('click');

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
          mutation: updateAlertStatusMutation,
          variables: {
            iid: '1527542',
            status: 'TRIGGERED',
            projectPath: 'projectPath',
          },
        });
      });

      it('stops updating when the request fails', () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockReturnValue(Promise.reject(new Error()));
        findStatusDropdownItem().vm.$emit('click');
        expect(findStatusLoadingIcon().exists()).toBe(false);
        expect(findStatus().text()).toBe('Triggered');
      });
    });
  });

  describe('Statuses', () => {
    it('renders default translated statuses', () => {
      mountComponent({});
      expect(findAlertStatus().props('statuses')).toBe(PAGE_CONFIG.OPERATIONS.STATUSES);
      expect(findStatus().text()).toBe('Triggered');
    });

    it('renders translated statuses', () => {
      const status = 'TEST';
      const statuses = { [status]: 'Test' };
      mountComponent({ data: { alert: { ...mockAlert, status } }, provide: { statuses } });
      expect(findAlertStatus().props('statuses')).toBe(statuses);
      expect(findStatus().text()).toBe(statuses.TEST);
    });
  });
});
