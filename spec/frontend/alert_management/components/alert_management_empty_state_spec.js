import { GlEmptyState, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AlertManagementEmptyState from '~/alert_management/components/alert_management_empty_state.vue';
import defaultProvideValues from '../mocks/alerts_provide_config.json';

describe('AlertManagementEmptyState', () => {
  let wrapper;

  function mountComponent({ provide = {} } = {}) {
    wrapper = shallowMount(AlertManagementEmptyState, {
      provide: {
        ...defaultProvideValues,
        ...provide,
      },
    });
  }

  beforeEach(() => {
    mountComponent();
  });

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findButton = () => wrapper.findComponent(GlButton);

  describe('Empty state', () => {
    it('renders empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
    });

    it("does not show the button is user can't enable alert management", () => {
      expect(findButton().exists()).toBe(false);
    });

    it('shows the button if user can enable alert management', () => {
      mountComponent({
        provide: {
          userCanEnableAlertManagement: true,
          alertManagementEnabled: true,
        },
      });

      expect(findButton().exists()).toBe(true);
      expect(findButton().text()).toBe('Authorize external service');
    });
  });
});
