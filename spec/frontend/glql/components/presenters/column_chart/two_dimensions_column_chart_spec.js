import { GlStackedColumnChart } from '@gitlab/ui/src/charts';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TwoDimensionsColumnChart from '~/glql/components/presenters/column_chart/two_dimensions_column_chart.vue';

const PRIMARY_DIM = { key: 'user', label: 'User', name: 'user', type: 'dimension' };
const SECONDARY_DIM = { key: 'language', label: 'Language', name: 'language', type: 'dimension' };
const METRIC = { key: 'totalCount', label: 'Total count', name: 'totalCount', type: 'metric' };
const DATA = {
  nodes: [
    { user: 'u0', language: 'ruby', totalCount: 12 },
    { user: 'u0', language: 'python', totalCount: 6 },
    { user: 'u2', language: 'ruby', totalCount: 6 },
    { user: 'u2', language: 'python', totalCount: 5 },
  ],
};

describe('TwoDimensionsColumnChart', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(TwoDimensionsColumnChart, {
      propsData: {
        data: DATA,
        primaryDimension: PRIMARY_DIM,
        secondaryDimension: SECONDARY_DIM,
        metric: METRIC,
      },
    });
  };

  const findChart = () => wrapper.findComponent(GlStackedColumnChart);

  beforeEach(() => {
    createComponent();
  });

  it('renders GlStackedColumnChart with stacked presentation', () => {
    expect(findChart().exists()).toBe(true);
    expect(findChart().props('presentation')).toBe('stacked');
  });

  it('groups by the primary dimension with the secondary dimension as bar names', () => {
    expect(findChart().props('groupBy')).toEqual(['u0', 'u2']);
    expect(findChart().props('bars')).toEqual([
      { name: 'ruby', data: [12, 6] },
      { name: 'python', data: [6, 5] },
    ]);
  });

  it('labels the axes from the primary dimension and metric', () => {
    expect(findChart().props('xAxisTitle')).toBe('User');
    expect(findChart().props('yAxisTitle')).toBe('Total count');
  });
});
