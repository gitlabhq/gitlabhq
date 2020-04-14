import { SUPPORTED_FORMATS } from '~/lib/utils/unit_format';
import {
  uniqMetricsId,
  parseEnvironmentsResponse,
  removeLeadingSlash,
  mapToDashboardViewModel,
} from '~/monitoring/stores/utils';
import { NOT_IN_DB_PREFIX } from '~/monitoring/constants';

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
              xLabel: '',
              xAxis: {
                name: '',
              },
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
              xLabel: '',
              xAxis: {
                name: '',
              },
              y_label: 'Y Label A',
              yAxis: {
                name: 'Y Label A',
                format: 'number',
                precision: 2,
              },
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

  describe('panel mapping', () => {
    const panelTitle = 'Panel Title';
    const yAxisName = 'Y Axis Name';

    let dashboard;

    const setupWithPanel = panel => {
      dashboard = {
        panel_groups: [
          {
            panels: [panel],
          },
        ],
      };
    };

    const getMappedPanel = () => mapToDashboardViewModel(dashboard).panelGroups[0].panels[0];

    it('panel with x_label', () => {
      setupWithPanel({
        title: panelTitle,
        x_label: 'x label',
      });

      expect(getMappedPanel()).toEqual({
        title: panelTitle,
        xLabel: 'x label',
        xAxis: {
          name: 'x label',
        },
        y_label: '',
        yAxis: {
          name: '',
          format: SUPPORTED_FORMATS.number,
          precision: 2,
        },
        metrics: [],
      });
    });

    it('group y_axis defaults', () => {
      setupWithPanel({
        title: panelTitle,
      });

      expect(getMappedPanel()).toEqual({
        title: panelTitle,
        xLabel: '',
        y_label: '',
        xAxis: {
          name: '',
        },
        yAxis: {
          name: '',
          format: SUPPORTED_FORMATS.number,
          precision: 2,
        },
        metrics: [],
      });
    });

    it('panel with y_axis.name', () => {
      setupWithPanel({
        y_axis: {
          name: yAxisName,
        },
      });

      expect(getMappedPanel().y_label).toBe(yAxisName);
      expect(getMappedPanel().yAxis.name).toBe(yAxisName);
    });

    it('panel with y_axis.name and y_label, displays y_axis.name', () => {
      setupWithPanel({
        y_label: 'Ignored Y Label',
        y_axis: {
          name: yAxisName,
        },
      });

      expect(getMappedPanel().y_label).toBe(yAxisName);
      expect(getMappedPanel().yAxis.name).toBe(yAxisName);
    });

    it('group y_label', () => {
      setupWithPanel({
        y_label: yAxisName,
      });

      expect(getMappedPanel().y_label).toBe(yAxisName);
      expect(getMappedPanel().yAxis.name).toBe(yAxisName);
    });

    it('group y_axis format and precision', () => {
      setupWithPanel({
        title: panelTitle,
        y_axis: {
          precision: 0,
          format: SUPPORTED_FORMATS.bytes,
        },
      });

      expect(getMappedPanel().yAxis.format).toBe(SUPPORTED_FORMATS.bytes);
      expect(getMappedPanel().yAxis.precision).toBe(0);
    });

    it('group y_axis unsupported format defaults to number', () => {
      setupWithPanel({
        title: panelTitle,
        y_axis: {
          format: 'invalid_format',
        },
      });

      expect(getMappedPanel().yAxis.format).toBe(SUPPORTED_FORMATS.number);
    });

    // This property allows single_stat panels to render percentile values
    it('group maxValue', () => {
      setupWithPanel({
        max_value: 100,
      });

      expect(getMappedPanel().maxValue).toBe(100);
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
      const dashboard = dashboardWithMetric({ label: 'Panel Label' });

      expect(getMappedMetric(dashboard)).toEqual({
        label: expect.any(String),
        metricId: expect.any(String),
        loading: false,
        result: null,
        state: null,
      });
    });

    it('creates a metric with a correct id', () => {
      const dashboard = dashboardWithMetric({
        id: 'http_responses',
        metric_id: 1,
      });

      expect(getMappedMetric(dashboard).metricId).toEqual('1_http_responses');
    });

    it('creates a metric without a default label', () => {
      const dashboard = dashboardWithMetric({});

      expect(getMappedMetric(dashboard)).toMatchObject({
        label: undefined,
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
    { input: { id: 1 }, expected: `${NOT_IN_DB_PREFIX}_1` },
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
