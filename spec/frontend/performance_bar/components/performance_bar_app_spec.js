import { mount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import PerformanceBarApp from '~/performance_bar/components/performance_bar_app.vue';
import PerformanceBarStore from '~/performance_bar/stores/performance_bar_store';

describe('performance bar app', () => {
  const store = new PerformanceBarStore();
  store.addRequest('123', 'https://gitlab.com', '', {}, 'GET');
  const wrapper = mount(PerformanceBarApp, {
    propsData: {
      store,
      env: 'development',
      requestId: '123',
      requestMethod: 'GET',
      statsUrl: 'https://log.gprd.gitlab.net/app/dashboards#/view/',
      peekUrl: '/-/peek/results',
    },
  });

  const flamegraphDiv = () => wrapper.find('#peek-flamegraph');
  const flamegrapLinks = () => flamegraphDiv().findAllComponents(GlLink);

  it('creates three flamegraph buttons based on the path', () => {
    expect(flamegrapLinks()).toHaveLength(3);

    ['wall', 'cpu', 'object'].forEach((path, index) => {
      expect(flamegrapLinks().at(index).attributes('href')).toBe(
        `https://gitlab.com?performance_bar=flamegraph&stackprof_mode=${path}`,
      );
    });
    expect(flamegrapLinks().at(0).attributes('href')).toEqual(
      'https://gitlab.com?performance_bar=flamegraph&stackprof_mode=wall',
    );
    expect(flamegrapLinks().at(1).attributes('href')).toEqual(
      'https://gitlab.com?performance_bar=flamegraph&stackprof_mode=cpu',
    );
    expect(flamegrapLinks().at(2).attributes('href')).toEqual(
      'https://gitlab.com?performance_bar=flamegraph&stackprof_mode=object',
    );
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
