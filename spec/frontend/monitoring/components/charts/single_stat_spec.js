import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import SingleStatChart from '~/monitoring/components/charts/single_stat.vue';
import { singleStatGraphData } from '../../graph_data';

describe('Single Stat Chart component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(SingleStatChart, {
      propsData: {
        graphData: singleStatGraphData({}, { unit: 'MB' }),
        ...props,
      },
    });
  };

  const findChart = () => wrapper.find(GlSingleStat);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('statValue', () => {
      it('should display the correct value', () => {
        expect(findChart().props('value')).toBe('1.00');
      });

      it('should display the correct value unit', () => {
        expect(findChart().props('unit')).toBe('MB');
      });

      it('should change the value representation to a percentile one', () => {
        createComponent({
          graphData: singleStatGraphData({ max_value: 120 }, { value: 91 }),
        });

        expect(findChart().props('value')).toBe('75.83');
        expect(findChart().props('unit')).toBe('%');
      });

      it('should display NaN for non numeric maxValue values', () => {
        createComponent({
          graphData: singleStatGraphData({ max_value: 'not a number' }),
        });

        expect(findChart().props('value')).toContain('NaN');
      });

      it('should display NaN for missing query values', () => {
        createComponent({
          graphData: singleStatGraphData({ max_value: 120 }, { value: 'NaN' }),
        });

        expect(findChart().props('value')).toContain('NaN');
      });

      it('should not display `unit` when `unit` is undefined', () => {
        createComponent({
          graphData: singleStatGraphData({}, { unit: undefined }),
        });

        expect(findChart().props('value')).not.toContain('undefined');
      });

      it('should not display `unit` when `unit` is null', () => {
        createComponent({
          graphData: singleStatGraphData({}, { unit: null }),
        });

        expect(findChart().props('value')).not.toContain('null');
      });

      describe('when a field attribute is set', () => {
        it('displays a label value instead of metric value when field attribute is used', () => {
          createComponent({
            graphData: singleStatGraphData({ field: 'job' }, { isVector: true }),
          });

          expect(findChart().props('value')).toContain('prometheus');
        });

        it('displays No data to display if field attribute is not present', () => {
          createComponent({
            graphData: singleStatGraphData({ field: 'this-does-not-exist' }),
          });

          expect(findChart().props('value')).toContain('No data to display');
        });
      });
    });
  });
});
