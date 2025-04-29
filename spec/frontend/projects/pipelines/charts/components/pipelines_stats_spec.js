import { GlSkeletonLoader, GlLink } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import PipelinesStats from '~/projects/pipelines/charts/components/pipelines_stats.vue';

const failedPipelinesLink = '/pipelines?status=failed';

describe('PipelinesStats', () => {
  let wrapper;

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findAllSingleStats = () => wrapper.findAllComponents(GlSingleStat).wrappers;
  const findStatById = (identifier) =>
    findAllSingleStats().find((stat) => stat.attributes('id') === identifier);
  const findFailedPipelinesLink = () => wrapper.findComponent(GlLink);

  const createWrapper = ({ props } = {}) => {
    wrapper = shallowMount(PipelinesStats, {
      propsData: {
        ...props,
      },
      provide: {
        failedPipelinesLink,
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
      createWrapper({ props: { aggregate: mockAggregate } });
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
        href: failedPipelinesLink,
        'data-event-tracking': 'click_view_all_link_in_pipeline_analytics',
      });
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
    beforeEach(() => {
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

    it('renders stats with no values', () => {
      expect(findStatById('total-pipeline-runs').props('value')).toBe('-');
      expect(findStatById('failure-ratio').props('value')).toBe('-');
      expect(findStatById('success-ratio').props('value')).toBe('-');
    });
  });
});
