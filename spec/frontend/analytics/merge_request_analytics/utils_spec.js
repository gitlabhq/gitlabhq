import * as utils from '~/analytics/merge_request_analytics/utils';
import { filterToMRThroughputQueryObject } from '~/analytics/merge_request_analytics/utils';
import {
  expectedMonthData,
  throughputChartData,
  formattedThroughputChartData,
  throughputChartNoData,
  formattedMttmData,
  formattedMttmNoData,
  mockThroughputSearchFilters,
  mockThroughputFiltersQueryObject,
} from './mock_data';

jest.mock('~/alert');

describe('computeMonthRangeData', () => {
  const start = new Date('2020-05-17T00:00:00.000Z');
  const end = new Date('2020-07-17T00:00:00.000Z');

  it('returns the data as expected', () => {
    const monthData = utils.computeMonthRangeData(start, end);

    expect(monthData).toStrictEqual(expectedMonthData);
  });

  it('returns an empty array on an invalid date range', () => {
    const monthData = utils.computeMonthRangeData(end, start);

    expect(monthData).toStrictEqual([]);
  });
});

describe('formatThroughputChartData', () => {
  it('returns the data as expected', () => {
    const chartData = utils.formatThroughputChartData(throughputChartData);

    expect(chartData).toStrictEqual(formattedThroughputChartData);
  });

  it('returns an empty array if no data is passed to the util', () => {
    const chartData = utils.formatThroughputChartData();

    expect(chartData).toStrictEqual([]);
  });

  it('excludes the `__typename` key', () => {
    const [chartData] = utils.formatThroughputChartData(throughputChartData);

    chartData.data.forEach((item) => {
      expect(item[0].trim()).not.toEqual('__typename');
    });
  });
});

describe('computeMttmData', () => {
  it('returns the data as expected', () => {
    const mttmData = utils.computeMttmData(throughputChartData);

    expect(mttmData).toStrictEqual(formattedMttmData);
  });

  it('with no time to merge data', () => {
    const mttmData = utils.computeMttmData(throughputChartNoData);

    expect(mttmData).toStrictEqual(formattedMttmNoData);
  });
});

describe('filterToMRThroughputQueryObject', () => {
  it('converts filter tokens to filter object as expected', () => {
    expect(filterToMRThroughputQueryObject(mockThroughputSearchFilters)).toEqual(
      mockThroughputFiltersQueryObject,
    );
  });

  it('returns empty object if no filters have been applied', () => {
    expect(filterToMRThroughputQueryObject({})).toEqual({});
  });
});
