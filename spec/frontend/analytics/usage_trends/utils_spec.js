import {
  getAverageByMonth,
  getEarliestDate,
  generateDataKeys,
} from '~/analytics/usage_trends/utils';
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

  it('transforms a data point to the first of the month', () => {
    const item = mockCountsData1[0];
    const firstOfTheMonth = item.recordedAt.replace(/-[0-9]{2}$/, '-01');
    expect(getAverageByMonth([item])).toStrictEqual([[firstOfTheMonth, item.count]]);
  });

  it('uses sane defaults', () => {
    expect(getAverageByMonth()).toStrictEqual([]);
  });

  it('errors when passing null', () => {
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

describe('getEarliestDate', () => {
  it('returns the date of the final item in the array', () => {
    expect(getEarliestDate(mockCountsData1)).toBe('2020-06-12');
  });

  it('returns null for an empty array', () => {
    expect(getEarliestDate([])).toBeNull();
  });

  it("returns null if the array has data but `recordedAt` isn't defined", () => {
    expect(
      getEarliestDate(mockCountsData1.map(({ recordedAt: date, ...rest }) => ({ date, ...rest }))),
    ).toBeNull();
  });
});

describe('generateDataKeys', () => {
  const fakeQueries = [
    { identifier: 'from' },
    { identifier: 'first' },
    { identifier: 'to' },
    { identifier: 'last' },
  ];

  const defaultValue = 'default value';
  const res = generateDataKeys(fakeQueries, defaultValue);

  it('extracts each query identifier and sets them as object keys', () => {
    expect(Object.keys(res)).toEqual(['from', 'first', 'to', 'last']);
  });

  it('sets every value to the `defaultValue` provided', () => {
    expect(Object.values(res)).toEqual(Array(fakeQueries.length).fill(defaultValue));
  });
});
