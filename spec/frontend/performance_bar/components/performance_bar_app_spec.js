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
      peekUrl: '/-/peek/results',
      profileUrl: '?lineprofiler=true',
    },
  });

  it('sets the class to match the environment', () => {
    expect(wrapper.element.getAttribute('class')).toContain('development');
  });
});
