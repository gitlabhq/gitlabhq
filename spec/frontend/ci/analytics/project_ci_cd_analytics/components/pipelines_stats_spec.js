import { GlSkeletonLoader, GlLink } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/src/charts';
import { shallowMount } from '@vue/test-utils';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import PipelinesStats from '~/ci/analytics/project_ci_cd_analytics/components/pipelines_stats.vue';

const mockFailedPipelinesPath = '/pipelines?status=failed';

describe('PipelinesStats', () => {
  let wrapper;

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findAllSingleStats = () => wrapper.findAllComponents(GlSingleStat).wrappers;
  const findStatById = (identifier) =>
    findAllSingleStats().find((stat) => stat.attributes('id') === identifier);
  const findFailedPipelinesLink = () => wrapper.findComponent(GlLink);
  const findFailureRateHelpPopover = () =>
    wrapper.find('[data-testid="failure-ratio-help-popover"]');

  const createWrapper = ({ props } = {}) => {
    wrapper = shallowMount(PipelinesStats, {
      propsData: {
        ...props,
      },
    });
  };

  describe('when loading', () => {
    beforeEach(() => {
      createWrapper({ props: { loading: true } });
    });

    it('does not show stats', () => {
      expect(findAllSingleStats()).toHaveLength(0);
    });

    it('shows skeleton', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });
  });

  describe.each([undefined, null])('when no data is provided', (aggregate) => {
    beforeEach(() => {
      createWrapper({
        aggregate,
      });
    });

    it('renders stats with no values', () => {
      expect(findAllSingleStats()).toHaveLength(4);

      expect(findStatById('total-pipeline-runs').props('value')).toBe('-');
      expect(findStatById('median-duration').props('value')).toBe('-');
      expect(findStatById('failure-ratio').props('value')).toBe('-');
      expect(findStatById('success-ratio').props('value')).toBe('-');
    });

    it('does not render the failed pipelines link', () => {
      expect(findFailedPipelinesLink().exists()).toBe(false);
    });
  });

  describe('when data is provided', () => {
    const mockAggregate = {
      count: '200',
      successCount: '150',
      failedCount: '50',
      durationStatistics: {
        p50: 60 * 60 * 3 + 60 * 3,
      },
    };

    beforeEach(() => {
      createWrapper({
        props: {
          aggregate: mockAggregate,
          failedPipelinesPath: mockFailedPipelinesPath,
        },
      });
    });

    it('renders stats correctly', () => {
      expect(findAllSingleStats()).toHaveLength(4);

      expect(findStatById('total-pipeline-runs').props('shouldAnimate')).toBe(true);
      expect(findStatById('median-duration').props('shouldAnimate')).toBe(true);
      expect(findStatById('success-ratio').props('shouldAnimate')).toBe(true);
      expect(findStatById('failure-ratio').props('shouldAnimate')).toBe(true);
    });

    it('renders stats data', () => {
      expect(findStatById('total-pipeline-runs').props('value')).toBe('200');
      expect(findStatById('median-duration').props('value')).toBe('3h 3m');
      expect(findStatById('success-ratio').props('value')).toBe('75%');
      expect(findStatById('failure-ratio').props('value')).toBe('25%');
    });

    it('renders the failed pipelines link when failed count is greater than zero', () => {
      expect(findFailedPipelinesLink().attributes()).toMatchObject({
        href: mockFailedPipelinesPath,
        'data-event-tracking': 'click_view_all_link_in_pipeline_analytics',
      });
    });

    it('renders a help popover next to the Failure rate stat explaining the formula', () => {
      const popover = findFailureRateHelpPopover();

      expect(popover.exists()).toBe(true);
      expect(popover.findComponent(HelpPopover).props('options')).toEqual({
        title: 'How this is calculated?',
        content:
          "Rate = failed_pipelines / (success + failed). Canceled and skipped pipelines aren't included. Success rate is the inverse.",
      });
    });

    it('does not render the help popover on the Success rate stat', () => {
      expect(wrapper.find('[data-testid="success-ratio-help-popover"]').exists()).toBe(false);
    });
  });

  describe('when data is zero', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          aggregate: {
            count: '0',
            successCount: '0',
            failedCount: '0',
            durationStatistics: {
              p50: 0,
            },
          },
        },
      });
    });

    it('renders zero counts', () => {
      expect(findStatById('total-pipeline-runs').props('value')).toBe('0');
      expect(findStatById('median-duration').props('value')).toBe('0m');
      expect(findStatById('failure-ratio').props('value')).toBe('-');
      expect(findStatById('success-ratio').props('value')).toBe('-');
      expect(findFailedPipelinesLink().exists()).toBe(false);
    });
  });

  describe('when data is invalid', () => {
    let captureExceptionSpy;

    beforeEach(() => {
      captureExceptionSpy = jest.spyOn(Sentry, 'captureException').mockImplementation(() => {});
      createWrapper({
        props: {
          aggregate: {
            count: 'invalid',
            successCount: 'invalid',
            failedCount: 'invalid',
          },
        },
      });
    });

    afterEach(() => {
      captureExceptionSpy.mockRestore();
    });

    it('renders stats with no values', () => {
      expect(findStatById('total-pipeline-runs').props('value')).toBe('-');
      expect(findStatById('failure-ratio').props('value')).toBe('-');
      expect(findStatById('success-ratio').props('value')).toBe('-');
    });

    it('reports the parse error to Sentry', () => {
      expect(captureExceptionSpy).toHaveBeenCalled();
    });
  });
});
