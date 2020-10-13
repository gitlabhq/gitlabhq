import { getAverageByMonth } from '~/analytics/instance_statistics/utils';
import {
  mockCountsData1,
  mockCountsData2,
  countsMonthlyChartData1,
  countsMonthlyChartData2,
} from './mock_data';

describe('getAverageByMonth', () => {
  it('collects data into average by months', () => {
    expect(getAverageByMonth(mockCountsData1)).toStrictEqual(countsMonthlyChartData1);
    expect(getAverageByMonth(mockCountsData2)).toStrictEqual(countsMonthlyChartData2);
  });

  it('it transforms a data point to the first of the month', () => {
    const item = mockCountsData1[0];
    const firstOfTheMonth = item.recordedAt.replace(/-[0-9]{2}$/, '-01');
    expect(getAverageByMonth([item])).toStrictEqual([[firstOfTheMonth, item.count]]);
  });

  it('it uses sane defaults', () => {
    expect(getAverageByMonth()).toStrictEqual([]);
  });

  it('it errors when passing null', () => {
    expect(() => {
      getAverageByMonth(null);
    }).toThrow();
  });

  describe('when shouldRound = true', () => {
    const options = { shouldRound: true };

    it('rounds the averages', () => {
      const roundedData1 = countsMonthlyChartData1.map(([date, avg]) => [date, Math.round(avg)]);
      const roundedData2 = countsMonthlyChartData2.map(([date, avg]) => [date, Math.round(avg)]);
      expect(getAverageByMonth(mockCountsData1, options)).toStrictEqual(roundedData1);
      expect(getAverageByMonth(mockCountsData2, options)).toStrictEqual(roundedData2);
    });
  });
});
