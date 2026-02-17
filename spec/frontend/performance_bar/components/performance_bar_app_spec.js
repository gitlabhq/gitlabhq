import { shallowMount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import PerformanceBarApp from '~/performance_bar/components/performance_bar_app.vue';
import PerformanceBarStore from '~/performance_bar/stores/performance_bar_store';
import InfoApp from '~/performance_bar/components/info_modal/info_app.vue';

describe('performance bar app', () => {
  let wrapper;
  const store = new PerformanceBarStore();
  store.addRequest('123', 'https://gitlab.com', '', {}, 'GET');

  const createComponent = (props = {}) => {
    wrapper = shallowMount(PerformanceBarApp, {
      propsData: {
        store,
        env: 'development',
        requestId: '123',
        statsUrl: 'https://log.gprd.gitlab.net/app/dashboards#/view/',
        simulateSaas: false,
        ...props,
      },
      stubs: {
        GlEmoji: { template: '<div/>' },
      },
    });
  };

  const findInfoApp = () => wrapper.findComponent(InfoApp);

  describe('info section', () => {
    beforeEach(() => createComponent());

    it('renders the info section button', () => {
      expect(findInfoApp().exists()).toBe(true);
    });

    it('passes the currentRequest prop', () => {
      expect(findInfoApp().props().currentRequest).toEqual(store.findRequest('123'));
    });
  });

  describe('flamegraph buttons', () => {
    beforeEach(() => createComponent());

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
    beforeEach(() => createComponent());

    const memoryReportDiv = () => wrapper.find('#peek-memory-report');
    const memoryReportLink = () => memoryReportDiv().findComponent(GlLink);

    it('creates memory report button', () => {
      expect(memoryReportLink().attributes('href')).toEqual(
        'https://gitlab.com?performance_bar=memory',
      );
    });
  });

  describe('environment class', () => {
    beforeEach(() => createComponent());

    it('sets the class to match the environment', () => {
      expect(wrapper.element.getAttribute('class')).toContain('development');
    });
  });

  describe('changeCurrentRequest', () => {
    beforeEach(() => createComponent());

    it('emits a change-request event', () => {
      expect(wrapper.emitted('change-request')).toBeUndefined();

      wrapper.vm.changeCurrentRequest('123');

      expect(wrapper.emitted('change-request')).toBeDefined();
      expect(wrapper.emitted('change-request')[0]).toEqual(['123']);
    });
  });

  describe('SaaS indicator', () => {
    const findSaasIndicator = () => wrapper.find('[data-testid="simulate-saas-indicator"]');

    describe('when simulateSaas is false', () => {
      beforeEach(() => createComponent());

      it('does not render', () => {
        expect(findSaasIndicator().exists()).toBe(false);
      });
    });

    describe('when simulateSaas is true', () => {
      beforeEach(() => createComponent({ simulateSaas: true }));

      it('renders', () => {
        expect(findSaasIndicator().exists()).toBe(true);
        expect(findSaasIndicator().text()).toBe('SaaS');
      });
    });
  });
});
