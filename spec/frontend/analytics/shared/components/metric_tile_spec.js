import { GlSingleStat } from '@gitlab/ui/src/charts';
import { shallowMount } from '@vue/test-utils';
import MetricTile from '~/analytics/shared/components/metric_tile.vue';
import MetricPopover from '~/analytics/shared/components/metric_popover.vue';
import { visitUrl } from '~/lib/utils/url_utility';
import { FLOW_METRICS } from '~/analytics/shared/constants';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

describe('MetricTile', () => {
  let wrapper;

  const namespacePath = 'foo';
  const defaultMetric = {
    identifier: 'issues',
    value: '10',
    label: 'New issues',
    description: 'Number of new issues created',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(MetricTile, {
      propsData: {
        metric: defaultMetric,
        namespacePath,
        ...props,
      },
    });
  };

  const findSingleStat = () => wrapper.findComponent(GlSingleStat);
  const findPopover = () => wrapper.findComponent(MetricPopover);

  describe('template', () => {
    it('renders a metric popover', () => {
      createComponent();

      expect(findPopover().props()).toMatchObject({
        metric: defaultMetric,
        target: defaultMetric.identifier,
      });
    });

    describe('links', () => {
      describe.each`
        isProjectNamespace | expectedURL
        ${false}           | ${'/groups/foo/-/issues_analytics'}
        ${true}            | ${'/foo/-/analytics/issues_analytics'}
      `(
        'metric has links and isProjectNamespace=$isProjectNamespace',
        ({ isProjectNamespace, expectedURL }) => {
          beforeEach(() => {
            const metric = {
              ...defaultMetric,
              groupLink: '-/issues_analytics',
              projectLink: '-/analytics/issues_analytics',
            };

            createComponent({ metric, isProjectNamespace });
          });

          it('visits the correct URL on click', () => {
            findSingleStat().vm.$emit('click');

            expect(visitUrl).toHaveBeenCalledWith(expectedURL);
          });

          it('passes correct URL to popover', () => {
            expect(findPopover().props('metricUrl')).toBe(expectedURL);
          });
        },
      );

      describe(`metric doesn't have links`, () => {
        beforeEach(() => {
          const metric = {
            identifier: 'commits',
            value: '10',
            label: 'Commits',
            description: 'Number of commits pushed to the default branch',
          };
          createComponent({ metric });
        });

        it('does not visit URL on click', () => {
          findSingleStat().vm.$emit('click');

          expect(visitUrl).not.toHaveBeenCalled();
        });

        it('does not pass URL to popover', () => {
          expect(findPopover().props('metricUrl')).toBe('');
        });
      });

      describe.each([FLOW_METRICS.LEAD_TIME, FLOW_METRICS.CYCLE_TIME])(
        'for %s metric',
        (identifier) => {
          beforeEach(() => {
            const metric = {
              identifier,
              label: 'Mock label',
              groupLink: `/groups/-/analytics/${identifier}`,
              projectLink: `-/analytics/${identifier}`,
              description: 'Mock description',
            };

            createComponent({ metric });
          });

          it('does not visit URL on click', () => {
            findSingleStat().vm.$emit('click');

            expect(visitUrl).not.toHaveBeenCalled();
          });

          it('does not pass URL to popover', () => {
            expect(findPopover().props('metricUrl')).toBe('');
          });
        },
      );
    });

    describe('number formatting', () => {
      it(`will render 0 decimal places for an integer value`, () => {
        createComponent();

        expect(findSingleStat().props('animationDecimalPlaces')).toBe(0);
      });

      it(`will render 1 decimal place for a float value`, () => {
        const metric = { ...defaultMetric, value: '10.5' };
        createComponent({ metric });

        expect(findSingleStat().props('animationDecimalPlaces')).toBe(1);
      });

      it.each([10.53, 10.53324])(
        'will round to a maximum of 2 decimal place for a float value given %s',
        (value) => {
          const metric = { ...defaultMetric, value };
          createComponent({ metric });

          expect(findSingleStat().props('animationDecimalPlaces')).toBe(2);
        },
      );

      it('will render using delimiters', () => {
        const metric = { ...defaultMetric, value: '10000' };
        createComponent({ metric });

        expect(findSingleStat().props('useDelimiters')).toBe(true);
      });
    });
  });
});
