import { shallowMount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import AlertManagementEmptyState from '~/alert_management/components/alert_management_empty_state.vue';

describe('AlertManagementEmptyState', () => {
  let wrapper;

  function mountComponent({
    props = {
      alertManagementEnabled: false,
      userCanEnableAlertManagement: false,
    },
  } = {}) {
    wrapper = shallowMount(AlertManagementEmptyState, {
      propsData: {
        enableAlertManagementPath: '/link',
        emptyAlertSvgPath: 'illustration/path',
        ...props,
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

  describe('Empty state', () => {
    it('shows empty state', () => {
      expect(wrapper.find(GlEmptyState).exists()).toBe(true);
    });
  });
});
