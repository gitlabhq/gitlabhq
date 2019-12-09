import { shallowMount } from '@vue/test-utils';
import DetailedMetric from '~/performance_bar/components/detailed_metric.vue';
import RequestWarning from '~/performance_bar/components/request_warning.vue';

describe('detailedMetric', () => {
  const createComponent = props =>
    shallowMount(DetailedMetric, {
      propsData: {
        ...props,
      },
    });

  describe('when the current request has no details', () => {
    const wrapper = createComponent({
      currentRequest: {},
      metric: 'gitaly',
      header: 'Gitaly calls',
      details: 'details',
      keys: ['feature', 'request'],
    });

    it('does not render the element', () => {
      expect(wrapper.isEmpty()).toBe(true);
    });
  });

  describe('when the current request has details', () => {
    const requestDetails = [
      { duration: '100', feature: 'find_commit', request: 'abcdef', backtrace: ['hello', 'world'] },
      { duration: '23', feature: 'rebase_in_progress', request: '', backtrace: ['world', 'hello'] },
    ];

    describe('with a default metric name', () => {
      const wrapper = createComponent({
        currentRequest: {
          details: {
            gitaly: {
              duration: '123ms',
              calls: '456',
              details: requestDetails,
              warnings: ['gitaly calls: 456 over 30'],
            },
          },
        },
        metric: 'gitaly',
        header: 'Gitaly calls',
        keys: ['feature', 'request'],
      });

      it('displays details', () => {
        expect(wrapper.text().replace(/\s+/g, ' ')).toContain('123ms / 456');
      });

      it('adds a modal with a table of the details', () => {
        wrapper
          .findAll('.performance-bar-modal td:nth-child(1)')
          .wrappers.forEach((duration, index) => {
            expect(duration.text()).toContain(requestDetails[index].duration);
          });

        wrapper
          .findAll('.performance-bar-modal td:nth-child(2)')
          .wrappers.forEach((feature, index) => {
            expect(feature.text()).toContain(requestDetails[index].feature);
          });

        wrapper
          .findAll('.performance-bar-modal td:nth-child(2)')
          .wrappers.forEach((request, index) => {
            expect(request.text()).toContain(requestDetails[index].request);
          });

        expect(wrapper.find('.text-expander.js-toggle-button')).not.toBeNull();

        wrapper.findAll('.performance-bar-modal td:nth-child(2)').wrappers.forEach(request => {
          expect(request.text()).toContain('world');
        });
      });

      it('displays the metric title', () => {
        expect(wrapper.text()).toContain('gitaly');
      });

      it('displays request warnings', () => {
        expect(wrapper.find(RequestWarning).exists()).toBe(true);
      });
    });

    describe('when using a custom metric title', () => {
      const wrapper = createComponent({
        currentRequest: {
          details: {
            gitaly: {
              duration: '123ms',
              calls: '456',
              details: requestDetails,
            },
          },
        },
        metric: 'gitaly',
        title: 'custom',
        header: 'Gitaly calls',
        keys: ['feature', 'request'],
      });

      it('displays the custom title', () => {
        expect(wrapper.text()).toContain('custom');
      });
    });
  });
});
