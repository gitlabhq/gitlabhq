import { shallowMount } from '@vue/test-utils';
import PerformanceBarApp from '~/performance_bar/components/performance_bar_app.vue';
import PerformanceBarStore from '~/performance_bar/stores/performance_bar_store';

describe('performance bar app', () => {
  const store = new PerformanceBarStore();
  const wrapper = shallowMount(PerformanceBarApp, {
    propsData: {
      store,
      env: 'development',
      requestId: '123',
      statsUrl: 'https://log.gprd.gitlab.net/app/dashboards#/view/',
      peekUrl: '/-/peek/results',
      profileUrl: '?lineprofiler=true',
    },
  });

  it('sets the class to match the environment', () => {
    expect(wrapper.element.getAttribute('class')).toContain('development');
  });

  describe('changeCurrentRequest', () => {
    it('emits a change-request event', () => {
      expect(wrapper.emitted('change-request')).toBeUndefined();

      wrapper.vm.changeCurrentRequest('123');

      expect(wrapper.emitted('change-request')).toBeDefined();
      expect(wrapper.emitted('change-request')[0]).toEqual(['123']);
    });
  });
});
