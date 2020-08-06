import { shallowMount } from '@vue/test-utils';
import { GlGaugeChart } from '@gitlab/ui/dist/charts';
import GaugeChart from '~/monitoring/components/charts/gauge.vue';
import { gaugeChartGraphData } from '../../graph_data';

describe('Gauge Chart component', () => {
  const defaultGraphData = gaugeChartGraphData();

  let wrapper;

  const findGaugeChart = () => wrapper.find(GlGaugeChart);

  const createWrapper = ({ ...graphProps } = {}) => {
    wrapper = shallowMount(GaugeChart, {
      propsData: {
        graphData: {
          ...defaultGraphData,
          ...graphProps,
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('chart component', () => {
    it('is rendered when props are passed', () => {
      createWrapper();

      expect(findGaugeChart().exists()).toBe(true);
    });
  });

  describe('min and max', () => {
    const MIN_DEFAULT = 0;
    const MAX_DEFAULT = 100;

    it('are passed to chart component', () => {
      createWrapper();

      expect(findGaugeChart().props('min')).toBe(100);
      expect(findGaugeChart().props('max')).toBe(1000);
    });

    const invalidCases = [undefined, NaN, 'a string'];

    it.each(invalidCases)(
      'if min has invalid value, defaults are used for both min and max',
      invalidValue => {
        createWrapper({ minValue: invalidValue });

        expect(findGaugeChart().props('min')).toBe(MIN_DEFAULT);
        expect(findGaugeChart().props('max')).toBe(MAX_DEFAULT);
      },
    );

    it.each(invalidCases)(
      'if max has invalid value, defaults are used for both min and max',
      invalidValue => {
        createWrapper({ minValue: invalidValue });

        expect(findGaugeChart().props('min')).toBe(MIN_DEFAULT);
        expect(findGaugeChart().props('max')).toBe(MAX_DEFAULT);
      },
    );

    it('if min is bigger than max, defaults are used for both min and max', () => {
      createWrapper({ minValue: 100, maxValue: 0 });

      expect(findGaugeChart().props('min')).toBe(MIN_DEFAULT);
      expect(findGaugeChart().props('max')).toBe(MAX_DEFAULT);
    });
  });

  describe('thresholds', () => {
    it('thresholds are set on chart', () => {
      createWrapper();

      expect(findGaugeChart().props('thresholds')).toEqual([500, 800]);
    });

    it('when no thresholds are defined, a default threshold is defined at 95% of max_value', () => {
      createWrapper({
        minValue: 0,
        maxValue: 100,
        thresholds: {},
      });

      expect(findGaugeChart().props('thresholds')).toEqual([95]);
    });

    it('when out of min-max bounds thresholds are defined, a default threshold is defined at 95% of the range between min_value and max_value', () => {
      createWrapper({
        thresholds: {
          values: [-10, 1500],
        },
      });

      expect(findGaugeChart().props('thresholds')).toEqual([855]);
    });

    describe('when mode is absolute', () => {
      it('only valid threshold values are used', () => {
        createWrapper({
          thresholds: {
            mode: 'absolute',
            values: [undefined, 10, 110, NaN, 'a string', 400],
          },
        });

        expect(findGaugeChart().props('thresholds')).toEqual([110, 400]);
      });

      it('if all threshold values are invalid, a default threshold is defined at 95% of the range between min_value and max_value', () => {
        createWrapper({
          thresholds: {
            mode: 'absolute',
            values: [NaN, undefined, 'a string', 1500],
          },
        });

        expect(findGaugeChart().props('thresholds')).toEqual([855]);
      });
    });

    describe('when mode is percentage', () => {
      it('when values outside of 0-100 bounds are used, a default threshold is defined at 95% of max_value', () => {
        createWrapper({
          thresholds: {
            mode: 'percentage',
            values: [110],
          },
        });

        expect(findGaugeChart().props('thresholds')).toEqual([855]);
      });

      it('if all threshold values are invalid, a default threshold is defined at 95% of max_value', () => {
        createWrapper({
          thresholds: {
            mode: 'percentage',
            values: [NaN, undefined, 'a string', 1500],
          },
        });

        expect(findGaugeChart().props('thresholds')).toEqual([855]);
      });
    });
  });

  describe('split (the number of ticks on the chart arc)', () => {
    const SPLIT_DEFAULT = 10;

    it('is passed to chart as prop', () => {
      createWrapper();

      expect(findGaugeChart().props('splitNumber')).toBe(20);
    });

    it('if not explicitly set, passes a default value to chart', () => {
      createWrapper({ split: '' });

      expect(findGaugeChart().props('splitNumber')).toBe(SPLIT_DEFAULT);
    });

    it('if set as a number that is not an integer, passes the default value to chart', () => {
      createWrapper({ split: 10.5 });

      expect(findGaugeChart().props('splitNumber')).toBe(SPLIT_DEFAULT);
    });

    it('if set as a negative number, passes the default value to chart', () => {
      createWrapper({ split: -10 });

      expect(findGaugeChart().props('splitNumber')).toBe(SPLIT_DEFAULT);
    });
  });

  describe('text (the text displayed on the gauge for the current value)', () => {
    it('displays the query result value when format is not set', () => {
      createWrapper({ format: '' });

      expect(findGaugeChart().props('text')).toBe('3');
    });

    it('displays the query result value when format is set to invalid value', () => {
      createWrapper({ format: 'invalid' });

      expect(findGaugeChart().props('text')).toBe('3');
    });

    it('displays a formatted query result value when format is set', () => {
      createWrapper();

      expect(findGaugeChart().props('text')).toBe('3kB');
    });

    it('displays a placeholder value when metric is empty', () => {
      createWrapper({ metrics: [] });

      expect(findGaugeChart().props('text')).toBe('--');
    });
  });

  describe('value', () => {
    it('correct value is passed', () => {
      createWrapper();

      expect(findGaugeChart().props('value')).toBe(3);
    });
  });
});
