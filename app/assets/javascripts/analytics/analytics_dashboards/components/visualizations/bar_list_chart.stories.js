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
    <bar-list-chart :data="data" :options="options" />
  </div>`,
});

const WithDashboard = (args, { argTypes }) => ({
  components: { BarListChart, DashboardLayout },
  props: Object.keys(argTypes),
  template: `
      <dashboard-layout :panels="panelsConfig">
        <bar-list-chart :data="data" :options="options" />
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
Default.args = { data: whereCreditsWent, options: {} };

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

export const InDashboardPanel = WithDashboard.bind({});
InDashboardPanel.args = {
  data: whereCreditsWent,
  options: {},
  panelsConfig: [
    {
      id: '1',
      title: 'Where credits went',
      gridAttributes: { yPos: 0, xPos: 0, width: 12, height: 3 },
    },
  ],
};
