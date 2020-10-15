import { shallowMount } from '@vue/test-utils';
import AlertManagementList from '~/alert_management/components/alert_management_list_wrapper.vue';
import AlertManagementEmptyState from '~/alert_management/components/alert_management_empty_state.vue';
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

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  describe('Alert List Wrapper', () => {
    it('should show the empty state when alerts are not enabled', () => {
      expect(wrapper.find(AlertManagementEmptyState).exists()).toBe(true);
      expect(wrapper.find(AlertManagementTable).exists()).toBe(false);
    });

    it('should show the alerts table when alerts are enabled', () => {
      mountComponent({
        provide: {
          alertManagementEnabled: true,
        },
      });

      expect(wrapper.find(AlertManagementEmptyState).exists()).toBe(false);
      expect(wrapper.find(AlertManagementTable).exists()).toBe(true);
    });
  });
});
