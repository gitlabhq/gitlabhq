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

    it('updates series name from templates', () => {
      const config = {
        ...defaultConfig,
        name: '{{cmd}}',
      };

      const [result] = monitorHelper.makeDataSeries(
        [{ metric: { cmd: 'brpop' }, values: series }],
        config,
      );

      expect(result.name).toEqual('brpop');
    });

    it('supports space-padded template expressions', () => {
      const config = {
        ...defaultConfig,
        name: 'backend: {{ backend }}',
      };

      const [result] = monitorHelper.makeDataSeries(
        [{ metric: { backend: 'HA Server' }, values: series }],
        config,
      );

      expect(result.name).toEqual('backend: HA Server');
    });

    it('supports repeated template variables', () => {
      const config = { ...defaultConfig, name: '{{cmd}}, {{cmd}}' };

      const [result] = monitorHelper.makeDataSeries(
        [{ metric: { cmd: 'brpop' }, values: series }],
        config,
      );

      expect(result.name).toEqual('brpop, brpop');
    });

    it('supports hyphenated template variables', () => {
      const config = { ...defaultConfig, name: 'expired - {{ test-attribute }}' };

      const [result] = monitorHelper.makeDataSeries(
        [{ metric: { 'test-attribute': 'test-attribute-value' }, values: series }],
        config,
      );

      expect(result.name).toEqual('expired - test-attribute-value');
    });

    it('updates multiple series names from templates', () => {
      const config = {
        ...defaultConfig,
        name: '{{job}}: {{cmd}}',
      };

      const [result] = monitorHelper.makeDataSeries(
        [{ metric: { cmd: 'brpop', job: 'redis' }, values: series }],
        config,
      );

      expect(result.name).toEqual('redis: brpop');
    });

    it('updates name for each series', () => {
      const config = {
        ...defaultConfig,
        name: '{{cmd}}',
      };

      const [firstSeries, secondSeries] = monitorHelper.makeDataSeries(
        [
          { metric: { cmd: 'brpop' }, values: series },
          { metric: { cmd: 'zrangebyscore' }, values: series },
        ],
        config,
      );

      expect(firstSeries.name).toEqual('brpop');
      expect(secondSeries.name).toEqual('zrangebyscore');
    });
  });
});
