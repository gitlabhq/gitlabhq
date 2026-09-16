import DashboardLayout from 'storybook_helpers/dashboards/dashboard_layout.vue';
import BarListChart from './bar_list_chart.vue';

export default {
  component: BarListChart,
  title: 'analytics/analytics_dashboards/components/visualizations/bar_list_chart',
};

const Template = (args, { argTypes }) => ({
  components: { BarListChart },
  props: Object.keys(argTypes),
  template: `
  <div class="gl-h-48">
    <bar-list-chart :data="data" :value-labels="valueLabels" :color="color" :scale="scale" :options="options" />
  </div>`,
});

const WithDashboard = (args, { argTypes }) => ({
  components: { BarListChart, DashboardLayout },
  props: Object.keys(argTypes),
  template: `
      <dashboard-layout :panels="panelsConfig">
        <bar-list-chart :data="data" :value-labels="valueLabels" :color="color" :scale="scale" :options="options" />
      </dashboard-layout>`,
});

// "Where credits went", as rendered in the DAP Impact design prototype.
const whereCreditsWent = [
  { name: 'Chat', value: 85600, share: 89 },
  { name: 'Software Dev', value: 4600, share: 5 },
  { name: 'Developer', value: 2200, share: 2 },
  { name: 'Unattributed', value: 1400, share: 1 },
  { name: 'Code Suggestions', value: 833, share: 0.9 },
  { name: 'Fix Pipeline', value: 655, share: 0.7 },
  { name: 'Other (10)', value: 1300, share: 1 },
];

export const Default = Template.bind({});
Default.args = { data: whereCreditsWent, valueLabels: 'shareAndValue', options: {} };

// One row dwarfing the rest is the realistic case, and the one where a track
// matters most: without it the short bars have no context.
export const LongTail = Template.bind({});
LongTail.args = {
  data: [
    { name: 'Chat', value: 2570000, share: 97.2 },
    { name: 'Software Dev', value: 30000, share: 1.1 },
    { name: 'Developer', value: 20000, share: 0.8 },
    { name: 'Other (9)', value: 24000, share: 0.9 },
  ],
  options: {},
};

export const EvenDistribution = Template.bind({});
EvenDistribution.args = {
  data: [
    { name: 'Chat', value: 100000, share: 25 },
    { name: 'Software Dev', value: 100000, share: 25 },
    { name: 'Developer', value: 100000, share: 25 },
    { name: 'Code Suggestions', value: 100000, share: 25 },
  ],
  options: {},
};

// Category labels have a fixed column, so anything wider is truncated.
export const LongCategoryLabels = Template.bind({});
LongCategoryLabels.args = {
  data: [
    { name: 'Duo Agent Platform Chat sessions', value: 85600, share: 89 },
    { name: 'Software Development flows', value: 4600, share: 5 },
    { name: 'Root Cause Analysis', value: 2200, share: 2 },
  ],
  options: {},
};

const withShares = (rows) => {
  const total = rows.reduce((sum, { value }) => sum + value, 0);

  return rows.map((row) => ({ ...row, share: (row.value / total) * 100 }));
};

// "Users by activity", as rendered in the DAP Impact design prototype: the count is the
// headline, with how it moved against the previous period alongside.
const usersByActivity = withShares([
  { name: 'Chat', value: 1071, trend: { text: '+7%', variant: 'success' } },
  { name: 'Code Suggestions', value: 882, trend: { text: '+12%', variant: 'success' } },
  { name: 'Fix Pipeline', value: 358, trend: { text: '+24%', variant: 'success' } },
  { name: 'Software Development', value: 198, trend: { text: '+18%', variant: 'success' } },
  { name: 'Security Analyst Agent', value: 74, trend: { text: '+9%', variant: 'success' } },
  { name: 'Duo Planner', value: 69, trend: { text: '-4%', variant: 'danger' } },
  { name: 'CI Expert Agent', value: 40, trend: { text: 'New', variant: 'neutral' } },
  // No counterpart in the previous period, so its change is unknown.
  { name: 'Other (4)', value: 73 },
]);

export const ValueLabels = Template.bind({});
ValueLabels.args = {
  data: usersByActivity.map(({ trend, ...row }) => row),
  valueLabels: 'value',
  color: 'blue',
  scale: 'max',
  options: {},
};

export const WithTrends = Template.bind({});
WithTrends.args = {
  data: usersByActivity,
  valueLabels: 'value',
  color: 'blue',
  scale: 'max',
  options: {},
};

export const InDashboardPanel = WithDashboard.bind({});
InDashboardPanel.args = {
  data: whereCreditsWent,
  valueLabels: 'shareAndValue',
  options: {},
  panelsConfig: [
    {
      id: '1',
      title: 'Where credits went',
      gridAttributes: { yPos: 0, xPos: 0, width: 12, height: 3 },
    },
  ],
};
