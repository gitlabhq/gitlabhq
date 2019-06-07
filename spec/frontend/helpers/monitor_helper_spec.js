import * as monitorHelper from '~/helpers/monitor_helper';

describe('monitor helper', () => {
  const defaultConfig = { default: true, name: 'default name' };
  const name = 'data name';
  const series = [[1, 1], [2, 2], [3, 3]];
  const data = ({ metric = { default_name: name }, values = series } = {}) => [{ metric, values }];

  describe('makeDataSeries', () => {
    const expectedDataSeries = [
      {
        ...defaultConfig,
        data: series,
      },
    ];

    it('converts query results to data series', () => {
      expect(monitorHelper.makeDataSeries(data({ metric: {} }), defaultConfig)).toEqual(
        expectedDataSeries,
      );
    });

    it('returns an empty array if no query results exist', () => {
      expect(monitorHelper.makeDataSeries([], defaultConfig)).toEqual([]);
    });

    it('handles multi-series query results', () => {
      const expectedData = { ...expectedDataSeries[0], name: 'default name: data name' };

      expect(monitorHelper.makeDataSeries([...data(), ...data()], defaultConfig)).toEqual([
        expectedData,
        expectedData,
      ]);
    });

    it('excludes NaN values', () => {
      expect(
        monitorHelper.makeDataSeries(
          data({ metric: {}, values: [[1, 1], [2, NaN]] }),
          defaultConfig,
        ),
      ).toEqual([{ ...expectedDataSeries[0], data: [[1, 1]] }]);
    });
  });
});
