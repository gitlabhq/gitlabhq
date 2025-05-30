import { GlLink, GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MetricPopover from '~/analytics/shared/components/metric_popover.vue';

describe('MetricPopover', () => {
  let wrapper;

  const defaultMetricData = {
    label: 'Deployment frequency',
    description: 'Average number of deployments to production per day.',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(MetricPopover, {
      propsData: {
        metric: defaultMetricData,
        target: 'deployment-frequency',
        ...props,
      },
      stubs: {
        'gl-popover': { template: '<div><slot name="title"></slot><slot></slot></div>' },
      },
    });
  };

  const findMetricLabel = () => wrapper.findByTestId('metric-label');
  const findMetricLink = () => wrapper.findByTestId('metric-link');
  const findMetricDescription = () => wrapper.findByTestId('metric-description');
  const findMetricDocsLink = () => wrapper.findByTestId('metric-docs-link');
  const findMetricDocsLinkIcon = () => findMetricDocsLink().findComponent(GlIcon);
  const findMetricDetailsIcon = () => findMetricLink().findComponent(GlIcon);

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it(`renders the metric's label`, () => {
      expect(findMetricLabel().text()).toBe('Deployment frequency');
    });

    it(`renders the metric's description`, () => {
      expect(findMetricDescription().text()).toBe(
        'Average number of deployments to production per day.',
      );
    });

    it(`does not render the metric's link`, () => {
      expect(findMetricLink().exists()).toBe(false);
    });

    it(`does not render the metric's docs link`, () => {
      expect(findMetricDocsLink().exists()).toBe(false);
    });
  });

  describe('with links', () => {
    beforeEach(() => {
      const metric = {
        ...defaultMetricData,
        docsLink: '/help/user/analytics/dora_metrics#deployment-frequency',
      };

      createComponent({ metric, metricUrl: '-/analytics/dashboards/dora_metrics' });
    });

    it(`renders the metric's link`, () => {
      expect(findMetricLink().text()).toContain('View details');
      expect(findMetricLink().findComponent(GlLink).attributes('href')).toBe(
        '-/analytics/dashboards/dora_metrics',
      );
      expect(findMetricDetailsIcon().attributes('name')).toBe('chart');
    });

    it(`renders the metric's docs link`, () => {
      expect(findMetricDocsLink().text()).toBe('Go to docs');
      expect(findMetricDocsLink().attributes('href')).toBe(
        '/help/user/analytics/dora_metrics#deployment-frequency',
      );
      expect(findMetricDocsLinkIcon().attributes('name')).toBe('external-link');
    });
  });
});
