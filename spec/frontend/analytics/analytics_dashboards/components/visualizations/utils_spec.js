import {
  formatVisualizationTooltipTitle,
  formatVisualizationValue,
  humanizeDisplayUnit,
  calculateDecimalPlaces,
  humanizeChartTooltipValue,
  removeNullSeries,
  formatChartTooltipTitle,
} from '~/analytics/analytics_dashboards/components/visualizations/utils';
import {
  CHART_TOOLTIP_TITLE_FORMATTERS,
  NULL_SERIES_ID,
  UNITS,
} from '~/analytics/shared/constants';

describe('visualization utils', () => {
  describe('formatVisualizationValue', () => {
    describe('when the value is not numeric', () => {
      it.each(['abc', true, null, undefined])('returns the value without modification', (value) => {
        expect(formatVisualizationValue(value)).toBe(value);
      });
    });

    describe('when the value is an ISO date string', () => {
      it.each`
        dateStr                      | expected
        ${'2024-04-19T00:00:00.000'} | ${'Apr 19, 2024 12:00am UTC'}
        ${'2023-11-12T17:43:11.987'} | ${'Nov 12, 2023 5:43pm UTC'}
      `('returns date formatted as "$expected"', ({ dateStr, expected }) => {
        expect(formatVisualizationValue(dateStr)).toBe(expected);
      });
    });

    describe('when the value is numeric', () => {
      it.each([
        [123, '123'],
        [1234, '1,234'],
        [-123, '-123'],
        [123.12, '123'],
        [-1234.12, '-1,234'],
        ['1234567890', '1,234,567,890'],
        ['1234567890.123456', '1,234,567,890'],
        ['-1234567890', '-1,234,567,890'],
        ['-1234567890.123456', '-1,234,567,890'],
      ])('returns the formatted value', (value, expected) => {
        expect(formatVisualizationValue(value)).toBe(expected);
      });
    });
  });

  describe('formatVisualizationTooltipTitle', () => {
    describe('when params object is expected structure', () => {
      it.each`
        value                        | expected
        ${'2024-04-19T00:00:00.000'} | ${'Apr 19, 2024 12:00am UTC (AxisName)'}
        ${'2023-11-12T17:43:11.987'} | ${'Nov 12, 2023 5:43pm UTC (AxisName)'}
        ${'Some non date value'}     | ${'Some non date value (AxisName)'}
        ${12345}                     | ${'12345 (AxisName)'}
        ${true}                      | ${'true (AxisName)'}
        ${''}                        | ${' (AxisName)'}
      `('returns title formatted as "$expected"', ({ value, expected }) => {
        const title = `${value} (AxisName)`;
        const params = {
          seriesData: [
            {
              value: [value],
            },
          ],
        };

        expect(formatVisualizationTooltipTitle(title, params)).toEqual(expected);
      });
    });

    describe('when params object is unexpected structure', () => {
      it('returns title unchanged', () => {
        const title = 'Tooltip title';
        const params = {
          seriesData: [
            {
              value_some_other_property: [123],
            },
          ],
        };

        expect(formatVisualizationTooltipTitle(title, params)).toEqual(title);
      });
    });
  });

  describe('formatChartTooltipTitle', () => {
    const { DATE, TITLE_CASE, VALUE_ONLY } = CHART_TOOLTIP_TITLE_FORMATTERS;

    it.each`
      value                        | formatter     | expected
      ${'2024-04-19T00:00:00.000'} | ${DATE}       | ${'Apr 19, 2024'}
      ${'2023-11-12T17:43:11.987'} | ${DATE}       | ${'Nov 12, 2023'}
      ${'Deployment frequency'}    | ${TITLE_CASE} | ${'Deployment Frequency'}
      ${'deployment_frequency'}    | ${TITLE_CASE} | ${'Deployment Frequency'}
      ${'deployment-frequency'}    | ${TITLE_CASE} | ${'Deployment Frequency'}
      ${'Load Balancer East'}      | ${VALUE_ONLY} | ${'Load Balancer East'}
      ${'Load Balancer East'}      | ${undefined}  | ${'Load Balancer East (AxisName)'}
      ${null}                      | ${DATE}       | ${''}
    `('returns formatted title as expected', ({ value, formatter, expected }) => {
      const title = `${value} (AxisName)`;

      expect(formatChartTooltipTitle({ title, value, formatter })).toEqual(expected);
    });
  });

  describe('humanizeDisplayUnit', () => {
    it.each`
      unit            | data   | result
      ${'days'}       | ${'-'} | ${'days'}
      ${'days'}       | ${0.8} | ${'days'}
      ${'days'}       | ${1}   | ${'day'}
      ${'per_day'}    | ${1}   | ${'/day'}
      ${'percent'}    | ${1}   | ${'%'}
      ${'per_second'} | ${1}   | ${'per_second'}
    `('returns $result when data=$data and unit=$unit', ({ unit, data, result }) => {
      expect(humanizeDisplayUnit({ data, unit })).toBe(result);
    });
  });

  describe('humanizeChartTooltipValue', () => {
    it.each`
      unit                   | value        | result
      ${UNITS.COUNT}         | ${1234}      | ${'1,234'}
      ${UNITS.DAYS}          | ${3}         | ${'3 days'}
      ${UNITS.DAYS}          | ${1}         | ${'1 day'}
      ${UNITS.PER_DAY}       | ${10}        | ${'10 /day'}
      ${UNITS.PERCENT}       | ${0.8}       | ${'80.0%'}
      ${UNITS.TIME_INTERVAL} | ${5328}      | ${'1.5 hours'}
      ${undefined}           | ${'hello'}   | ${'hello'}
      ${undefined}           | ${undefined} | ${'No data'}
      ${undefined}           | ${null}      | ${'No data'}
    `('returns $result when value=$value and unit=$unit', ({ unit, value, result }) => {
      expect(humanizeChartTooltipValue({ unit, value })).toBe(result);
    });
  });

  describe('calculateDecimalPlaces', () => {
    it.each`
      decimalPlaces | data     | result
      ${3}          | ${0.875} | ${3}
      ${1}          | ${0.875} | ${1}
      ${0}          | ${0.875} | ${0}
      ${3}          | ${0}     | ${0}
      ${1}          | ${0}     | ${0}
      ${0}          | ${0}     | ${0}
    `(
      'returns $result when data=data and decimalPlaces=$decimalPlaces',
      ({ decimalPlaces, data, result }) => {
        expect(calculateDecimalPlaces({ data, decimalPlaces })).toBe(result);
      },
    );
  });
});

describe('removeNullSeries', () => {
  it('returns series data without null series', () => {
    const seriesData = [
      {
        seriesId: 'deployment_frequency',
        seriesName: 'Deployment Frequency',
        values: ['2025-03-28', 1000],
      },
      {
        seriesId: NULL_SERIES_ID,
        seriesName: 'No deployments during this period',
        values: ['2025-03-28', null],
      },
    ];

    expect(removeNullSeries(seriesData)).toEqual([
      {
        seriesId: 'deployment_frequency',
        seriesName: 'Deployment Frequency',
        values: ['2025-03-28', 1000],
      },
    ]);
  });
});
