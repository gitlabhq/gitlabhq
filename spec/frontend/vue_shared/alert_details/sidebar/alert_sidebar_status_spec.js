import { GlDropdown, GlDropdownItem, GlLoadingIcon } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import updateAlertStatusMutation from '~/graphql_shared/mutations/alert_status_update.mutation.graphql';
import AlertStatus from '~/vue_shared/alert_details/components/alert_status.vue';
import AlertSidebarStatus from '~/vue_shared/alert_details/components/sidebar/sidebar_status.vue';
import { PAGE_CONFIG } from '~/vue_shared/alert_details/constants';
import mockAlerts from '../mocks/alerts.json';

const mockAlert = mockAlerts[0];

describe('Alert Details Sidebar Status', () => {
  let wrapper;
  const findStatusDropdown = () => wrapper.findComponent(GlDropdown);
  const findStatusDropdownItem = () => wrapper.findComponent(GlDropdownItem);
  const findStatusLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findStatusDropdownHeader = () => wrapper.findByTestId('dropdown-header');
  const findAlertStatus = () => wrapper.findComponent(AlertStatus);
  const findStatus = () => wrapper.findByTestId('status');
  const findSidebarIcon = () => wrapper.findByTestId('status-icon');

  function mountComponent({
    data,
    sidebarCollapsed = true,
    loading = false,
    stubs = {},
    provide = {},
  } = {}) {
    wrapper = mountExtended(AlertSidebarStatus, {
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

  describe('sidebar expanded', () => {
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

    it('does not display the collapsed sidebar icon', () => {
      expect(findSidebarIcon().exists()).toBe(false);
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

      it('renders default translated statuses', () => {
        mountComponent({ sidebarCollapsed: false });
        expect(findAlertStatus().props('statuses')).toBe(PAGE_CONFIG.OPERATIONS.STATUSES);
        expect(findStatus().text()).toBe('Triggered');
      });

      it('emits "alert-update" when the status has been updated', () => {
        mountComponent({ sidebarCollapsed: false });
        expect(wrapper.emitted('alert-update')).toBeUndefined();
        findAlertStatus().vm.$emit('handle-updating');
        expect(wrapper.emitted('alert-update')).toEqual([[]]);
      });

      it('renders translated statuses', () => {
        const status = 'TEST';
        const statuses = { [status]: 'Test' };
        mountComponent({
          data: { alert: { ...mockAlert, status } },
          provide: { statuses },
          sidebarCollapsed: false,
        });
        expect(findAlertStatus().props('statuses')).toBe(statuses);
        expect(findStatus().text()).toBe(statuses.TEST);
      });
    });
  });

  describe('sidebar collapsed', () => {
    beforeEach(() => {
      mountComponent({
        data: { alert: mockAlert },
        loading: false,
      });
    });
    it('does not display the status dropdown', () => {
      expect(findStatusDropdown().exists()).toBe(false);
    });

    it('does display the collapsed sidebar icon', () => {
      expect(findSidebarIcon().exists()).toBe(true);
    });
  });
});
