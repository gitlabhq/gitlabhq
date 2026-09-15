import DashboardLayout from 'storybook_helpers/dashboards/dashboard_layout.vue';
import DivergingBarChart from './diverging_bar_chart.vue';

export default {
  component: DivergingBarChart,
  title: 'analytics/analytics_dashboards/components/visualizations/diverging_bar_chart',
};

const Template = (args, { argTypes }) => ({
  components: { DivergingBarChart },
  props: Object.keys(argTypes),
  template: `
  <div class="gl-h-48">
    <diverging-bar-chart
      :data="data"
      :series-names="seriesNames"
      :options="options"
    />
  </div>`,
});

const WithDashboard = (args, { argTypes }) => ({
  components: { DivergingBarChart, DashboardLayout },
  props: Object.keys(argTypes),
  template: `
      <dashboard-layout :panels="panelsConfig">
        <diverging-bar-chart
          :data="data"
          :series-names="seriesNames"
          :options="options"
        />
      </dashboard-layout>`,
});

const seriesNames = ['Share of users', 'Share of sessions'];

const usersVsSessions = [
  { name: 'Power (100+)', values: [107, 3467] },
  { name: 'Heavy (25–99)', values: [288, 2111] },
  { name: 'Regular (5–24)', values: [472, 902] },
  { name: 'Light (1–4)', values: [531, 172] },
];

export const Default = Template.bind({});
Default.args = { data: usersVsSessions, seriesNames, options: {} };

export const EvenDistribution = Template.bind({});
EvenDistribution.args = {
  data: [
    { name: 'Power (100+)', values: [250, 250] },
    { name: 'Heavy (25–99)', values: [250, 250] },
    { name: 'Regular (5–24)', values: [250, 250] },
    { name: 'Light (1–4)', values: [250, 250] },
  ],
  seriesNames,
  options: {},
};

export const EmptyTier = Template.bind({});
EmptyTier.args = {
  data: [
    { name: 'Power (100+)', values: [0, 0] },
    { name: 'Heavy (25–99)', values: [14, 480] },
    { name: 'Regular (5–24)', values: [203, 1120] },
    { name: 'Light (1–4)', values: [889, 297] },
  ],
  seriesNames,
  options: {},
};

// The centred column is a share of the width, so long names truncate.
export const LongCategoryLabels = Template.bind({});
LongCategoryLabels.args = {
  data: [
    { name: 'Power users — 100 or more sessions', values: [107, 3467] },
    { name: 'Heavy users — 25 to 99 sessions', values: [288, 2111] },
    { name: 'Regular users — 5 to 24 sessions', values: [472, 902] },
  ],
  seriesNames,
  options: {},
};

export const InDashboardPanel = WithDashboard.bind({});
InDashboardPanel.args = {
  data: usersVsSessions,
  seriesNames,
  options: {},
  panelsConfig: [
    {
      id: '1',
      title: 'Share of users vs share of sessions',
      gridAttributes: { yPos: 0, xPos: 0, width: 12, height: 3 },
    },
  ],
};
