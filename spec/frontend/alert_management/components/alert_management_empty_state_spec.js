import { GlEmptyState } from '@gitlab/ui';
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

  const EmptyState = () => wrapper.findComponent(GlEmptyState);

  describe('Empty state', () => {
    it('shows empty state', () => {
      expect(EmptyState().exists()).toBe(true);
    });
  });
});
