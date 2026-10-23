import { VISUALIZATION_SLUG_VSD_DORA_METRICS_TABLE } from '~/analytics/shared/constants';
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
  title: 'explore/analytics_dashboards/components/analytics_dashboard_panel',
};

const Template = (args, { argTypes }) => ({
  components: { PanelWithStubbedFetch },
  provide: {
    namespaceId: '1',
    namespaceFullPath: 'gitlab-org/gitlab',
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

export const WithFooter = Template.bind({});
WithFooter.args = {
  title: 'Code Suggestions',
  visualization: weeklyVisualization,
  footer: { dashboardViewLink: { text: 'View adoption', view: 1 } },
};

// A visualization component that defines panel actions by emitting the
// `set-actions` event, which the panel forwards to its `setActions` method.
const VisualizationWithActions = {
  name: 'VisualizationWithActions',
  props: {
    data: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  emits: ['set-actions'],
  mounted() {
    this.$emit('set-actions', [
      { text: 'Open GitLab.com', href: 'https://gitlab.com', icon: 'external-link' },
      { text: 'Reload page', action: () => window.location.reload(), icon: 'retry' },
    ]);
  },
  template: `<div class="gl-text-subtle">Visualization providing panel actions</div>`,
};

// Simulates the generic visualization component defining panel actions.
// The data source must return non-empty data, otherwise the panel renders
// its empty state and the visualization (which emits the actions) never mounts.
const PanelWithActions = {
  name: 'PanelWithActions',
  extends: AnalyticsDashboardPanel,
  components: { VisualizationWithActions },
  methods: {
    async importDataSourceModule(dataType) {
      return async () => dataByType[dataType];
    },
  },
};

const actionsVisualization = {
  slug: 'visualization_with_actions',
  type: 'VisualizationWithActions',
  data: { type: 'code_suggestions_weekly', query: {} },
  options: {},
};

const ActionsTemplate = (args, { argTypes }) => ({
  components: { PanelWithActions },
  provide: {
    namespaceId: '1',
    namespaceFullPath: 'gitlab-org/gitlab',
    isProject: true,
    dataSourceClickhouse: false,
    overviewCountsAggregationEnabled: true,
    glAbilities: {},
    glLicensedFeatures: {},
  },
  props: Object.keys(argTypes),
  template: `
    <div class="gl-h-48">
      <panel-with-actions v-bind="$props" />
    </div>`,
});

export const WithActions = ActionsTemplate.bind({});
WithActions.args = {
  title: 'Code Suggestions',
  visualization: actionsVisualization,
};

const basePanelProvide = {
  namespaceId: '1',
  namespaceFullPath: 'gitlab-org/gitlab',
  isProject: true,
  dataSourceClickhouse: false,
  overviewCountsAggregationEnabled: true,
  glAbilities: {},
  glLicensedFeatures: {},
};

// Each alert state comes from what the data source does, so every story gets a panel
// whose data source is the given fetch function.
const createPanelTemplate = (fetch, provide = {}) => {
  const PanelWithFetch = {
    name: 'PanelWithFetch',
    extends: AnalyticsDashboardPanel,
    methods: {
      async importDataSourceModule() {
        return fetch;
      },
    },
  };

  return (args, { argTypes }) => ({
    components: { PanelWithFetch },
    provide: { ...basePanelProvide, ...provide },
    props: Object.keys(argTypes),
    template: `
      <div class="gl-h-48">
        <panel-with-fetch v-bind="$props" />
      </div>`,
  });
};

export const FetchError = createPanelTemplate(async () => {
  throw new Error('Request failed with status code 500');
}).bind({});
FetchError.args = {
  title: 'Code Suggestions',
  visualization: weeklyVisualization,
};

export const Warning = createPanelTemplate(async ({ setAlerts }) => {
  setAlerts({
    title: 'Partial results',
    warnings: ['Archived projects are not included in this chart.'],
  });
  return weeklyData;
}).bind({});
Warning.args = {
  title: 'Code Suggestions',
  visualization: weeklyVisualization,
};

export const Information = createPanelTemplate(async ({ setAlerts }) => {
  setAlerts({
    title: 'About this data',
    alerts: ['Data is refreshed once a day.'],
  });
  return weeklyData;
}).bind({});
Information.args = {
  title: 'Code Suggestions',
  visualization: weeklyVisualization,
};

export const InvalidVisualizationConfiguration = createPanelTemplate(async () => weeklyData).bind(
  {},
);
InvalidVisualizationConfiguration.args = {
  title: 'Code Suggestions',
  visualization: {
    ...weeklyVisualization,
    errors: ["property '/panels/0/visualization' is missing required keys: type"],
  },
};

const doraVisualization = {
  ...weeklyVisualization,
  slug: VISUALIZATION_SLUG_VSD_DORA_METRICS_TABLE,
};

export const InsufficientPermissions = createPanelTemplate(async () => weeklyData, {
  glAbilities: { readDora4Analytics: false },
  glLicensedFeatures: { dora4Analytics: true },
}).bind({});
InsufficientPermissions.args = {
  title: 'DORA metrics',
  visualization: doraVisualization,
};

export const Unlicensed = createPanelTemplate(async () => weeklyData, {
  glAbilities: { readDora4Analytics: true },
  glLicensedFeatures: { dora4Analytics: false },
}).bind({});
Unlicensed.args = {
  title: 'DORA metrics',
  visualization: doraVisualization,
};

export const EmptyData = createPanelTemplate(async () => []).bind({});
EmptyData.args = {
  title: 'Code Suggestions',
  visualization: weeklyVisualization,
};
