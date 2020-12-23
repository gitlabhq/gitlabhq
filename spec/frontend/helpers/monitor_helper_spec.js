import { getSeriesLabel, makeDataSeries } from '~/helpers/monitor_helper';

describe('monitor helper', () => {
  const defaultConfig = { default: true, name: 'default name' };
  const name = 'data name';
  const series = [
    [1, 1],
    [2, 2],
    [3, 3],
  ];

  describe('getSeriesLabel', () => {
    const metricAttributes = { __name__: 'up', app: 'prometheus' };

    it('gets a single attribute label', () => {
      expect(getSeriesLabel('app', metricAttributes)).toBe('app: prometheus');
    });

    it('gets a templated label', () => {
      expect(getSeriesLabel('{{__name__}}', metricAttributes)).toBe('up');
      expect(getSeriesLabel('{{app}}', metricAttributes)).toBe('prometheus');
      expect(getSeriesLabel('{{missing}}', metricAttributes)).toBe('{{missing}}');
    });

    it('gets a multiple label', () => {
      expect(getSeriesLabel(null, metricAttributes)).toBe('__name__: up, app: prometheus');
      expect(getSeriesLabel('', metricAttributes)).toBe('__name__: up, app: prometheus');
    });

    it('gets a simple label', () => {
      expect(getSeriesLabel('A label', {})).toBe('A label');
    });
  });

  describe('makeDataSeries', () => {
    const data = ({ metric = { default_name: name }, values = series } = {}) => [
      { metric, values },
    ];

    const expectedDataSeries = [
      {
        ...defaultConfig,
        data: series,
      },
    ];

    it('converts query results to data series', () => {
      expect(makeDataSeries(data({ metric: {} }), defaultConfig)).toEqual(expectedDataSeries);
    });

    it('returns an empty array if no query results exist', () => {
      expect(makeDataSeries([], defaultConfig)).toEqual([]);
    });

    it('handles multi-series query results', () => {
      const expectedData = { ...expectedDataSeries[0], name: 'default name: data name' };

      expect(makeDataSeries([...data(), ...data()], defaultConfig)).toEqual([
        expectedData,
        expectedData,
      ]);
    });

    it('updates series name from templates', () => {
      const config = {
        ...defaultConfig,
        name: '{{cmd}}',
      };

      const [result] = makeDataSeries([{ metric: { cmd: 'brpop' }, values: series }], config);

      expect(result.name).toEqual('brpop');
    });

    it('supports a multi metric label template expression', () => {
      const config = {
        ...defaultConfig,
        name: '',
      };

      const [result] = makeDataSeries(
        [
          {
            metric: {
              backend: 'HA Server',
              frontend: 'BA Server',
              app: 'prometheus',
              instance: 'k8 cluster 1',
            },
            values: series,
          },
        ],
        config,
      );

      expect(result.name).toBe(
        'backend: HA Server, frontend: BA Server, app: prometheus, instance: k8 cluster 1',
      );
    });

    it('supports space-padded template expressions', () => {
      const config = {
        ...defaultConfig,
        name: 'backend: {{ backend }}',
      };

      const [result] = makeDataSeries(
        [{ metric: { backend: 'HA Server' }, values: series }],
        config,
      );

      expect(result.name).toEqual('backend: HA Server');
    });

    it('supports repeated template variables', () => {
      const config = { ...defaultConfig, name: '{{cmd}}, {{cmd}}' };

      const [result] = makeDataSeries([{ metric: { cmd: 'brpop' }, values: series }], config);

      expect(result.name).toEqual('brpop, brpop');
    });

    it('supports hyphenated template variables', () => {
      const config = { ...defaultConfig, name: 'expired - {{ test-attribute }}' };

      const [result] = makeDataSeries(
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

      const [result] = makeDataSeries(
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

      const [firstSeries, secondSeries] = makeDataSeries(
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
