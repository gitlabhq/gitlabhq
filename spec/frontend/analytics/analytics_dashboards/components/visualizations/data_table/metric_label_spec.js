import { GlPopover, GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { EVENT_LABEL_CLICK_METRIC_IN_DASHBOARD_TABLE } from '~/analytics/shared/constants';
import MetricLabel from '~/analytics/analytics_dashboards/components/visualizations/data_table/metric_label.vue';

describe('Metric label', () => {
  let wrapper;

  const identifier = 'issues';
  const metricLabel = 'Issues created';
  const link = '/groups/test/-/issues_analytics';

  const createWrapper = (props = {}) => {
    wrapper = mountExtended(MetricLabel, {
      propsData: {
        identifier,
        ...props,
      },
    });
  };

  const findMetricLabel = () => wrapper.findByTestId('metric_label');
  const findInfoIcon = () => wrapper.findByTestId('info_icon');
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findPopoverLink = () => wrapper.findComponent(GlPopover).findComponent(GlLink);

  it('renders the metric label text', () => {
    createWrapper({ link });

    expect(findMetricLabel().text()).toBe(metricLabel);
  });

  describe('with a `link`', () => {
    beforeEach(() => {
      createWrapper({ link });
    });

    it('renders a link using the supplied URL', () => {
      expect(findMetricLabel().attributes('href')).toBe(link);
    });
  });

  describe('without a `link`', () => {
    beforeEach(() => {
      createWrapper({ link: '' });
    });

    it('renders the label without a link', () => {
      expect(findMetricLabel().text()).toBe(metricLabel);
      expect(findMetricLabel().attributes('href')).toBeUndefined();
    });
  });

  describe('click tracking', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    it('tracks the click event when a trackingProperty is set', () => {
      const trackingProperty = 'trackingProperty';
      createWrapper({ link, trackingProperty });

      findMetricLabel().vm.$emit('click');

      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_LABEL_CLICK_METRIC_IN_DASHBOARD_TABLE,
        {
          label: identifier,
          property: trackingProperty,
        },
        undefined,
      );
    });

    it('does not track the click event when trackingProperty is blank', () => {
      createWrapper({ link });

      findMetricLabel().vm.$emit('click');

      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      expect(trackEventSpy).not.toHaveBeenCalled();
    });
  });

  describe('popover', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('targets the info icon', () => {
      expect(findPopover().props('target')).toBe(findInfoIcon().attributes('id'));
    });

    it('renders popover content based on the metric identifier', () => {
      expect(findPopover().props('title')).toBe(metricLabel);
      expect(findPopover().text()).toContain('Number of new issues created.');
      expect(findPopoverLink().attributes('href')).toBe('/help/user/group/issues_analytics/_index');
      expect(findPopoverLink().text()).toBe(MetricLabel.i18n.docsLabel);
    });
  });
});
