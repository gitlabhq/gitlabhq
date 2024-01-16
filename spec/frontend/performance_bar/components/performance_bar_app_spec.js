import { mount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import PerformanceBarApp from '~/performance_bar/components/performance_bar_app.vue';
import PerformanceBarStore from '~/performance_bar/stores/performance_bar_store';

describe('performance bar app', () => {
  let wrapper;
  const store = new PerformanceBarStore();
  store.addRequest('123', 'https://gitlab.com', '', {}, 'GET');
  const createComponent = () => {
    wrapper = mount(PerformanceBarApp, {
      propsData: {
        store,
        env: 'development',
        requestId: '123',
        requestMethod: 'GET',
        statsUrl: 'https://log.gprd.gitlab.net/app/dashboards#/view/',
        peekUrl: '/-/peek/results',
      },
      stubs: {
        GlEmoji: { template: '<div/>' },
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('flamegraph buttons', () => {
    const flamegraphDiv = () => wrapper.find('#peek-flamegraph');
    const flamegraphLinks = () => flamegraphDiv().findAllComponents(GlLink);

    it('creates three flamegraph buttons based on the path', () => {
      expect(flamegraphLinks()).toHaveLength(3);

      ['wall', 'cpu', 'object'].forEach((path, index) => {
        expect(flamegraphLinks().at(index).attributes('href')).toBe(
          `https://gitlab.com?performance_bar=flamegraph&stackprof_mode=${path}`,
        );
      });
    });
  });

  describe('memory report button', () => {
    const memoryReportDiv = () => wrapper.find('#peek-memory-report');
    const memoryReportLink = () => memoryReportDiv().findComponent(GlLink);

    it('creates memory report button', () => {
      expect(memoryReportLink().attributes('href')).toEqual(
        'https://gitlab.com?performance_bar=memory',
      );
    });
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
