import { GlLineChart } from '@gitlab/ui/dist/charts';
import { GlEmptyState } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PerformanceGraph from '~/ml/experiment_tracking/components/performance_graph.vue';
import { MOCK_CANDIDATES } from '../routes/experiments/show/mock_data';

describe('PerformanceGraph', () => {
  let wrapper;
  const MOCK_METRICS = ['auc', 'l1_ratio', 'rmse'];

  const createWrapper = (candidates = MOCK_CANDIDATES, metricNames = MOCK_METRICS) => {
    wrapper = shallowMountExtended(PerformanceGraph, {
      propsData: {
        candidates,
        metricNames,
        emptyStateSvgPath: 'illustrations/status/status-new-md.svg',
      },
    });
  };

  const findLineChart = () => wrapper.findComponent(GlLineChart);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  describe('rendering', () => {
    it('renders the component', () => {
      createWrapper();

      expect(wrapper.props('candidates')).toEqual(MOCK_CANDIDATES);
      expect(wrapper.props('metricNames')).toEqual(MOCK_METRICS);
      expect(findEmptyState().exists()).toBe(false);
    });

    it('renders the correct data', () => {
      createWrapper();

      expect(findLineChart().props('data').length).toBe(MOCK_METRICS.length);
      expect(findLineChart().props('data')[0].name).toBe('auc');
      expect(findLineChart().props('data')[1].name).toBe('l1_ratio');
      expect(findLineChart().props('data')[2].name).toBe('rmse');
      expect(findLineChart().props('data')[0].data.length).toBe(4);
      expect(findLineChart().props('data')[1].data.length).toBe(5);
      expect(findLineChart().props('data')[2].data.length).toBe(1);
    });

    it('sorts the data by created_at in ascending order', () => {
      createWrapper();

      const data = findLineChart()
        .props('data')[0]
        .data.map(({ value }) => value[1]);

      expect(data).toEqual([0.3, 0.4, 0.6, 0.5]);
    });
  });

  describe('empty state', () => {
    it('should show empty state if candidates are missing', () => {
      createWrapper([], MOCK_METRICS);

      expect(findLineChart().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(true);
    });

    it('should show empty state if metric names are missing', () => {
      createWrapper(MOCK_CANDIDATES, []);

      expect(findLineChart().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(true);
    });

    it('should show empty state if candidates and metric names are missing', () => {
      createWrapper([], []);

      expect(findLineChart().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(true);
    });
  });
});
