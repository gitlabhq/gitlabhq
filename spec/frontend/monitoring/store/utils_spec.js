import {
  uniqMetricsId,
  parseEnvironmentsResponse,
  removeLeadingSlash,
  mapToDashboardViewModel,
} from '~/monitoring/stores/utils';

const projectPath = 'gitlab-org/gitlab-test';

describe('mapToDashboardViewModel', () => {
  it('maps an empty dashboard', () => {
    expect(mapToDashboardViewModel({})).toEqual({
      dashboard: '',
      panelGroups: [],
    });
  });

  it('maps a simple dashboard', () => {
    const response = {
      dashboard: 'Dashboard Name',
      panel_groups: [
        {
          group: 'Group 1',
          panels: [
            {
              title: 'Title A',
              type: 'chart-type',
              y_label: 'Y Label A',
              metrics: [],
            },
          ],
        },
      ],
    };

    expect(mapToDashboardViewModel(response)).toEqual({
      dashboard: 'Dashboard Name',
      panelGroups: [
        {
          group: 'Group 1',
          key: 'group-1-0',
          panels: [
            {
              title: 'Title A',
              type: 'chart-type',
              y_label: 'Y Label A',
              metrics: [],
            },
          ],
        },
      ],
    });
  });

  describe('panel groups mapping', () => {
    it('key', () => {
      const response = {
        dashboard: 'Dashboard Name',
        panel_groups: [
          {
            group: 'Group A',
          },
          {
            group: 'Group B',
          },
          {
            group: '',
            unsupported_property: 'This should be removed',
          },
        ],
      };

      expect(mapToDashboardViewModel(response).panelGroups).toEqual([
        {
          group: 'Group A',
          key: 'group-a-0',
          panels: [],
        },
        {
          group: 'Group B',
          key: 'group-b-1',
          panels: [],
        },
        {
          group: '',
          key: 'default-2',
          panels: [],
        },
      ]);
    });
  });

  describe('metrics mapping', () => {
    const defaultLabel = 'Panel Label';
    const dashboardWithMetric = (metric, label = defaultLabel) => ({
      panel_groups: [
        {
          panels: [
            {
              y_label: label,
              metrics: [metric],
            },
          ],
        },
      ],
    });

    const getMappedMetric = dashboard => {
      return mapToDashboardViewModel(dashboard).panelGroups[0].panels[0].metrics[0];
    };

    it('creates a metric', () => {
      const dashboard = dashboardWithMetric({});

      expect(getMappedMetric(dashboard)).toEqual({
        label: expect.any(String),
        metricId: expect.any(String),
        metric_id: expect.any(String),
      });
    });

    it('creates a metric with a correct ids', () => {
      const dashboard = dashboardWithMetric({
        id: 'http_responses',
        metric_id: 1,
      });

      expect(getMappedMetric(dashboard)).toMatchObject({
        metricId: '1_http_responses',
        metric_id: '1_http_responses',
      });
    });

    it('creates a metric with a default label', () => {
      const dashboard = dashboardWithMetric({});

      expect(getMappedMetric(dashboard)).toMatchObject({
        label: defaultLabel,
      });
    });

    it('creates a metric with an endpoint and query', () => {
      const dashboard = dashboardWithMetric({
        prometheus_endpoint_path: 'http://test',
        query_range: 'http_responses',
      });

      expect(getMappedMetric(dashboard)).toMatchObject({
        prometheusEndpointPath: 'http://test',
        queryRange: 'http_responses',
      });
    });

    it('creates a metric with an ad-hoc property', () => {
      // This behavior is deprecated and should be removed
      // https://gitlab.com/gitlab-org/gitlab/issues/207198

      const dashboard = dashboardWithMetric({
        x_label: 'Another label',
        unkown_option: 'unkown_data',
      });

      expect(getMappedMetric(dashboard)).toMatchObject({
        x_label: 'Another label',
        unkown_option: 'unkown_data',
      });
    });
  });
});

describe('uniqMetricsId', () => {
  [
    { input: { id: 1 }, expected: 'undefined_1' },
    { input: { metric_id: 2 }, expected: '2_undefined' },
    { input: { metric_id: 2, id: 21 }, expected: '2_21' },
    { input: { metric_id: 22, id: 1 }, expected: '22_1' },
    { input: { metric_id: 'aaa', id: '_a' }, expected: 'aaa__a' },
  ].forEach(({ input, expected }) => {
    it(`creates unique metric ID with ${JSON.stringify(input)}`, () => {
      expect(uniqMetricsId(input)).toEqual(expected);
    });
  });
});

describe('parseEnvironmentsResponse', () => {
  [
    {
      input: null,
      output: [],
    },
    {
      input: undefined,
      output: [],
    },
    {
      input: [],
      output: [],
    },
    {
      input: [
        {
          id: '1',
          name: 'env-1',
        },
      ],
      output: [
        {
          id: 1,
          name: 'env-1',
          metrics_path: `${projectPath}/environments/1/metrics`,
        },
      ],
    },
    {
      input: [
        {
          id: 'gid://gitlab/Environment/12',
          name: 'env-12',
        },
      ],
      output: [
        {
          id: 12,
          name: 'env-12',
          metrics_path: `${projectPath}/environments/12/metrics`,
        },
      ],
    },
  ].forEach(({ input, output }) => {
    it(`parseEnvironmentsResponse returns ${JSON.stringify(output)} with input ${JSON.stringify(
      input,
    )}`, () => {
      expect(parseEnvironmentsResponse(input, projectPath)).toEqual(output);
    });
  });
});

describe('removeLeadingSlash', () => {
  [
    { input: null, output: '' },
    { input: '', output: '' },
    { input: 'gitlab-org', output: 'gitlab-org' },
    { input: 'gitlab-org/gitlab', output: 'gitlab-org/gitlab' },
    { input: '/gitlab-org/gitlab', output: 'gitlab-org/gitlab' },
    { input: '////gitlab-org/gitlab', output: 'gitlab-org/gitlab' },
  ].forEach(({ input, output }) => {
    it(`removeLeadingSlash returns ${output} with input ${input}`, () => {
      expect(removeLeadingSlash(input)).toEqual(output);
    });
  });
});
