import { shallowMount } from '@vue/test-utils';
import AlertManagementEmptyState from '~/alert_management/components/alert_management_empty_state.vue';
import AlertManagementList from '~/alert_management/components/alert_management_list_wrapper.vue';
import AlertManagementTable from '~/alert_management/components/alert_management_table.vue';
import defaultProvideValues from '../mocks/alerts_provide_config.json';

describe('AlertManagementList', () => {
  let wrapper;

  function mountComponent({ provide = {} } = {}) {
    wrapper = shallowMount(AlertManagementList, {
      provide: {
        ...defaultProvideValues,
        ...provide,
      },
    });
  }

  beforeEach(() => {
    mountComponent();
  });

  describe('Alert List Wrapper', () => {
    it('should show the empty state when alerts are not enabled', () => {
      expect(wrapper.findComponent(AlertManagementEmptyState).exists()).toBe(true);
      expect(wrapper.findComponent(AlertManagementTable).exists()).toBe(false);
    });

    it('should show the alerts table when alerts are enabled', () => {
      mountComponent({
        provide: {
          alertManagementEnabled: true,
        },
      });

      expect(wrapper.findComponent(AlertManagementEmptyState).exists()).toBe(false);
      expect(wrapper.findComponent(AlertManagementTable).exists()).toBe(true);
    });
  });
});
