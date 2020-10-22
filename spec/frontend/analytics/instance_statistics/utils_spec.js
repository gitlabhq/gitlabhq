import {
  getAverageByMonth,
  extractValues,
  sortByDate,
} from '~/analytics/instance_statistics/utils';
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

describe('extractValues', () => {
  it('extracts only requested values', () => {
    const data = { fooBar: { baz: 'quis' }, ignored: 'ignored' };
    expect(extractValues(data, ['bar'], 'foo', 'baz')).toEqual({ bazBar: 'quis' });
  });

  it('it renames with the `renameKey` if provided', () => {
    const data = { fooBar: { baz: 'quis' }, ignored: 'ignored' };
    expect(extractValues(data, ['bar'], 'foo', 'baz', { renameKey: 'renamed' })).toEqual({
      renamedBar: 'quis',
    });
  });

  it('is able to get nested data', () => {
    const data = { fooBar: { even: [{ further: 'nested' }] }, ignored: 'ignored' };
    expect(extractValues(data, ['bar'], 'foo', 'even[0].further')).toEqual({
      'even[0].furtherBar': 'nested',
    });
  });

  it('is able to extract multiple values', () => {
    const data = {
      fooBar: { baz: 'quis' },
      fooBaz: { baz: 'quis' },
      fooQuis: { baz: 'quis' },
    };
    expect(extractValues(data, ['bar', 'baz', 'quis'], 'foo', 'baz')).toEqual({
      bazBar: 'quis',
      bazBaz: 'quis',
      bazQuis: 'quis',
    });
  });

  it('returns empty data set when keys are not found', () => {
    const data = { foo: { baz: 'quis' }, ignored: 'ignored' };
    expect(extractValues(data, ['bar'], 'foo', 'baz')).toEqual({});
  });

  it('returns empty data when params are missing', () => {
    expect(extractValues()).toEqual({});
  });
});

describe('sortByDate', () => {
  it('sorts the array by date', () => {
    expect(sortByDate(mockCountsData1)).toStrictEqual([...mockCountsData1].reverse());
  });

  it('does not modify the original array', () => {
    expect(sortByDate(countsMonthlyChartData1)).not.toBe(countsMonthlyChartData1);
  });
});
