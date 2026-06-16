import { GlPopover, GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { EVENT_LABEL_CLICK_METRIC_IN_DASHBOARD_TABLE } from '~/analytics/shared/constants';
import MetricLabel from '~/analytics/analytics_dashboards/components/visualizations/data_table/metric_label.vue';

describe('Metric label', () => {
  let wrapper;

  const identifier = 'issues';
  const metricLabel = 'Issues created';
  const groupRequestPath = 'test';
  const groupMetricPath = '-/issues_analytics';
  const projectRequestPath = 'test/project';
  const projectMetricPath = '-/analytics/issues_analytics';
  const filterLabels = ['frontend', 'UX'];
  const labelParams = '?label_name[]=frontend&label_name[]=UX';

  const createWrapper = (props = {}) => {
    wrapper = mountExtended(MetricLabel, {
      propsData: {
        identifier,
        requestPath: groupRequestPath,
        isProject: false,
        ...props,
      },
    });
  };

  const findMetricLabel = () => wrapper.findByTestId('metric_label');
  const findInfoIcon = () => wrapper.findByTestId('info_icon');
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findPopoverLink = () => wrapper.findComponent(GlPopover).findComponent(GlLink);

  describe('drill-down link', () => {
    describe.each`
      isProject | relativeUrlRoot | requestPath           | metricPath           | url
      ${false}  | ${'/'}          | ${groupRequestPath}   | ${groupMetricPath}   | ${`/groups/${groupRequestPath}/-/issues_analytics`}
      ${true}   | ${'/'}          | ${projectRequestPath} | ${projectMetricPath} | ${`/${projectRequestPath}/-/analytics/issues_analytics`}
      ${false}  | ${'/path'}      | ${groupRequestPath}   | ${groupMetricPath}   | ${`/path/groups/${groupRequestPath}/-/issues_analytics`}
      ${true}   | ${'/path'}      | ${projectRequestPath} | ${projectMetricPath} | ${`/path/${projectRequestPath}/-/analytics/issues_analytics`}
    `(
      'when isProject=$isProject and relativeUrlRoot=$relativeUrlRoot',
      ({ isProject, relativeUrlRoot, requestPath, url }) => {
        const trackingProperty = 'trackingProperty';

        beforeEach(() => {
          gon.relative_url_root = relativeUrlRoot;
        });

        describe('default', () => {
          beforeEach(() => {
            createWrapper({ identifier, requestPath, isProject, trackingProperty });
          });

          it('should render the correct link text', () => {
            expect(findMetricLabel().text()).toBe(metricLabel);
          });

          it('should render the correct link URL', () => {
            expect(findMetricLabel().attributes('href')).toBe(url);
          });

          describe('when clicked', () => {
            const { bindInternalEventDocument } = useMockInternalEventsTracking();

            beforeEach(() => {
              findMetricLabel().vm.$emit('click');
            });

            it('should track the click event', () => {
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
          });
        });

        describe('with a blank requestPath', () => {
          beforeEach(() => {
            createWrapper({ identifier, isProject, requestPath: '' });
          });

          it('does not render a link', () => {
            expect(findMetricLabel().text()).toBe(metricLabel);
            expect(findMetricLabel().attributes('href')).toBeUndefined();
          });
        });

        describe('with filter labels', () => {
          beforeEach(() => {
            createWrapper({ identifier, requestPath, isProject, filterLabels });
          });

          it(`should append filter labels params to the link's URL`, () => {
            const expectedUrl = `${url}${labelParams}`;

            expect(findMetricLabel().attributes('href')).toBe(expectedUrl);
          });
        });

        describe('with a blank trackingProperty', () => {
          beforeEach(() => {
            createWrapper({ identifier, requestPath, isProject });
          });

          describe('when clicked', () => {
            const { bindInternalEventDocument } = useMockInternalEventsTracking();

            beforeEach(() => {
              findMetricLabel().vm.$emit('click');
            });

            it('should not track the click event', () => {
              const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
              expect(trackEventSpy).not.toHaveBeenCalled();
            });
          });
        });
      },
    );
  });

  describe.each`
    metric                    | url
    ${'issues'}               | ${'/groups/test/-/issues_analytics'}
    ${'deployment_frequency'} | ${'/groups/test/-/analytics/dashboards/dora_metrics'}
  `('for the `$metric` metric', ({ metric, url }) => {
    beforeEach(() => {
      createWrapper({ identifier: metric });
    });

    it('should render the correct link URL', () => {
      expect(findMetricLabel().attributes('href')).toBe(url);
    });
  });

  describe('popover', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('shows the popover when the info icon is clicked', () => {
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
