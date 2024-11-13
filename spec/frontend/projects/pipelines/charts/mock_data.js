export const counts = {
  failed: 20000,
  success: 20000,
  total: 40000,
  successRatio: 50,
  failureRatio: 50,
  totalDuration: 116158,
};

export const timesChartData = {
  labels: ['as1234', 'kh423hy', 'ji56bvg', 'th23po'],
  values: [5, 3, 7, 4],
};

export const areaChartData = {
  labels: ['01 Jan', '02 Jan', '03 Jan', '04 Jan', '05 Jan'],
  totals: [4, 6, 3, 6, 7],
  success: [3, 5, 3, 3, 5],
};

export const lastYearChartData = {
  ...areaChartData,
  labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May'],
};

export const transformedAreaChartData = [
  {
    name: 'all',
    data: [
      ['01 Jan', 4],
      ['02 Jan', 6],
      ['03 Jan', 3],
      ['04 Jan', 6],
      ['05 Jan', 7],
    ],
  },
  {
    name: 'success',
    data: [
      ['01 Jan', 3],
      ['02 Jan', 3],
      ['03 Jan', 3],
      ['04 Jan', 3],
      ['05 Jan', 5],
    ],
  },
];

export const mockPipelineCount = {
  data: {
    project: {
      id: '1',
      totalPipelines: { count: 40, __typename: 'PipelineConnection' },
      successfulPipelines: { count: 23, __typename: 'PipelineConnection' },
      failedPipelines: { count: 1, __typename: 'PipelineConnection' },
      totalPipelineDuration: 2471,
      __typename: 'Project',
    },
  },
};

export const chartOptions = {
  xAxis: {
    name: 'X axis title',
    type: 'category',
  },
  yAxis: {
    name: 'Y axis title',
  },
};

export const mockPipelineStatistics = {
  data: {
    project: {
      id: '1',
      pipelineAnalytics: {
        weekPipelinesTotals: [0, 0, 0, 0, 0, 0, 0, 0],
        weekPipelinesLabels: [
          '24 November',
          '25 November',
          '26 November',
          '27 November',
          '28 November',
          '29 November',
          '30 November',
          '01 December',
        ],
        weekPipelinesSuccessful: [0, 0, 0, 0, 0, 0, 0, 0],
        monthPipelinesLabels: [
          '01 November',
          '02 November',
          '03 November',
          '04 November',
          '05 November',
          '06 November',
          '07 November',
          '08 November',
          '09 November',
          '10 November',
          '11 November',
          '12 November',
          '13 November',
          '14 November',
          '15 November',
          '16 November',
          '17 November',
          '18 November',
          '19 November',
          '20 November',
          '21 November',
          '22 November',
          '23 November',
          '24 November',
          '25 November',
          '26 November',
          '27 November',
          '28 November',
          '29 November',
          '30 November',
          '01 December',
        ],
        monthPipelinesTotals: [
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0,
        ],
        monthPipelinesSuccessful: [
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0,
        ],
        yearPipelinesLabels: [
          'December 2019',
          'January 2020',
          'February 2020',
          'March 2020',
          'April 2020',
          'May 2020',
          'June 2020',
          'July 2020',
          'August 2020',
          'September 2020',
          'October 2020',
          'November 2020',
          'December 2020',
        ],
        yearPipelinesTotals: [0, 0, 0, 0, 0, 0, 0, 0, 23, 7, 2, 2, 0],
        yearPipelinesSuccessful: [0, 0, 0, 0, 0, 0, 0, 0, 17, 5, 1, 0, 0],
        pipelineTimesLabels: [
          'b3781247',
          'b3781247',
          'a50ba059',
          '8e414f3b',
          'b2964d50',
          '7caa525b',
          '761b164e',
          'd3eccd18',
          'e2750f63',
          'e2750f63',
          '1dfb4b96',
          'b49d6f94',
          '66fa2f80',
          'e2750f63',
          'fc82cf15',
          '19fb20b2',
          '25f03a24',
          'e054110f',
          '0278b7b2',
          '38478c16',
          '38478c16',
          '38478c16',
          '1fb2103e',
          '97b99fb5',
          '8abc6e87',
          'c94e80e3',
          '5d349a50',
          '5d349a50',
          '9c581037',
          '02d95fb2',
        ],
        pipelineTimesValues: [
          1, 0, 0, 0, 0, 1, 1, 2, 1, 0, 1, 2, 2, 0, 4, 2, 1, 2, 1, 1, 0, 1, 1, 0, 1, 5, 2, 0, 0, 0,
        ],
        __typename: 'Analytics',
      },
      __typename: 'Project',
    },
  },
};

export const mockEmptyPipelineAnalytics = {
  data: {
    project: {
      id: 1,
      pipelineAnalytics: {
        aggregate: {
          count: '0',
          successCount: '0',
          failedCount: '0',
          durationStatistics: {
            p50: null,
          },
        },
      },
    },
  },
};

export const mockSevenDayPipelineAnalytics = {
  data: {
    project: {
      id: 1,
      pipelineAnalytics: {
        aggregate: {
          count: '100',
          successCount: '80',
          failedCount: '10',
          durationStatistics: {
            p50: '12345',
          },
        },
      },
    },
  },
};

export const mockNinetyDayPipelineAnalytics = {
  data: {
    project: {
      id: 1,
      pipelineAnalytics: {
        aggregate: {
          count: '1800',
          successCount: '600',
          failedCount: '360',
          durationStatistics: {
            p50: '23456',
          },
        },
      },
    },
  },
};
