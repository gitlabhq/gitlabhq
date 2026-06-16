import AnalyticsDashboardPanel from './analytics_dashboard_panel.vue';

const weeklyData = [
  {
    name: 'Suggestions accepted',
    data: [
      ['Feb 23', 1830],
      ['Mar 2', 2104],
      ['Mar 9', 1956],
      ['Mar 16', 2412],
      ['Mar 23', 2671],
      ['Mar 30', 2389],
      ['Apr 6', 2840],
      ['Apr 13', 3105],
      ['Apr 20', 2978],
      ['Apr 27', 3247],
      ['May 4', 3501],
      ['May 11', 3692],
    ],
  },
  {
    name: 'Suggestions shown',
    data: [
      ['Feb 23', 5490],
      ['Mar 2', 6312],
      ['Mar 9', 5868],
      ['Mar 16', 7236],
      ['Mar 23', 8013],
      ['Mar 30', 7167],
      ['Apr 6', 8520],
      ['Apr 13', 9315],
      ['Apr 20', 8934],
      ['Apr 27', 9741],
      ['May 4', 10503],
      ['May 11', 11076],
    ],
  },
];

const monthlyData = [
  {
    name: 'Suggestions accepted',
    data: [
      ['Jan', 8120],
      ['Feb', 9450],
      ['Mar', 10210],
      ['Apr', 11380],
      ['May', 12640],
      ['Jun', 13075],
    ],
  },
  {
    name: 'Suggestions shown',
    data: [
      ['Jan', 24360],
      ['Feb', 28350],
      ['Mar', 30630],
      ['Apr', 34140],
      ['May', 37920],
      ['Jun', 39225],
    ],
  },
];

const dataByType = {
  code_suggestions_weekly: weeklyData,
  code_suggestions_monthly: monthlyData,
};

const PanelWithStubbedFetch = {
  name: 'PanelWithStubbedFetch',
  extends: AnalyticsDashboardPanel,
  methods: {
    async importDataSourceModule(dataType) {
      return async () => dataByType[dataType];
    },
  },
};

const weeklyVisualization = {
  slug: 'code_suggestions_weekly_chart',
  type: 'LineChart',
  data: { type: 'code_suggestions_weekly', query: {} },
  options: {
    xAxis: { name: 'Week', type: 'category' },
    yAxis: { name: 'Suggestions' },
  },
};

const monthlyVisualization = {
  slug: 'code_suggestions_monthly_chart',
  type: 'LineChart',
  data: { type: 'code_suggestions_monthly', query: {} },
  options: {
    xAxis: { name: 'Month', type: 'category' },
    yAxis: { name: 'Suggestions' },
  },
};

export default {
  component: AnalyticsDashboardPanel,
  title: 'analytics/shared/components/analytics_dashboard_panel',
};

const Template = (args, { argTypes }) => ({
  components: { PanelWithStubbedFetch },
  provide: {
    namespaceId: '1',
    namespaceFullPath: 'gitlab-org/gitlab',
    namespaceName: 'GitLab',
    isProject: true,
    dataSourceClickhouse: false,
    overviewCountsAggregationEnabled: true,
    glAbilities: {},
    glLicensedFeatures: {},
  },
  props: Object.keys(argTypes),
  template: `
    <div class="gl-h-48">
      <panel-with-stubbed-fetch v-bind="$props" />
    </div>`,
});

export const Default = Template.bind({});
Default.args = {
  title: 'Code Suggestions',
  visualization: weeklyVisualization,
};

export const WithViews = Template.bind({});
WithViews.args = {
  title: 'Code Suggestions',
  visualization: weeklyVisualization,
  views: [
    { text: 'Weekly', visualization: weeklyVisualization },
    { text: 'Monthly', visualization: monthlyVisualization },
  ],
};
