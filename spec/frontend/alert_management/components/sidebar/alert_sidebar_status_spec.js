import { mount } from '@vue/test-utils';
import { GlDropdown, GlDropdownItem, GlLoadingIcon } from '@gitlab/ui';
import { trackAlertStatusUpdateOptions } from '~/alert_management/constants';
import AlertSidebarStatus from '~/alert_management/components/sidebar/sidebar_status.vue';
import updateAlertStatusMutation from '~/alert_management/graphql/mutations/update_alert_status.mutation.graphql';
import Tracking from '~/tracking';
import mockAlerts from '../../mocks/alerts.json';

const mockAlert = mockAlerts[0];

describe('Alert Details Sidebar Status', () => {
  let wrapper;
  const findStatusDropdown = () => wrapper.find(GlDropdown);
  const findStatusDropdownItem = () => wrapper.find(GlDropdownItem);
  const findStatusLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const findStatusDropdownHeader = () => wrapper.find('[data-testid="dropdown-header"]');

  function mountComponent({ data, sidebarCollapsed = true, loading = false, stubs = {} } = {}) {
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
        expect(wrapper.find('[data-testid="status"]').text()).toBe('Triggered');
      });
    });

    describe('Snowplow tracking', () => {
      beforeEach(() => {
        jest.spyOn(Tracking, 'event');
        mountComponent({
          props: { alertManagementEnabled: true, userCanEnableAlertManagement: true },
          data: { alert: mockAlert },
          loading: false,
        });
      });

      it('should track alert status updates', () => {
        Tracking.event.mockClear();
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue({});
        findStatusDropdownItem().vm.$emit('click');
        const status = findStatusDropdownItem().text();
        setImmediate(() => {
          const { category, action, label } = trackAlertStatusUpdateOptions;
          expect(Tracking.event).toHaveBeenCalledWith(category, action, {
            label,
            property: status,
          });
        });
      });
    });
  });
});
