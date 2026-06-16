import DashboardLayout from 'storybook_helpers/dashboards/dashboard_layout.vue';
import AreaChart from './area_chart.vue';

export default {
  component: AreaChart,
  title: 'analytics/analytics_dashboards/components/visualizations/area_chart',
};

const Template = (args, { argTypes }) => ({
  components: { AreaChart, DashboardLayout },
  props: Object.keys(argTypes),
  template: `
  <div class="gl-h-48">
    <area-chart :data="data" :options="options" />
  </div>`,
});

const WithDashboard = (args, { argTypes }) => ({
  components: { AreaChart, DashboardLayout },
  props: Object.keys(argTypes),
  template: `
      <dashboard-layout :panels="panelsConfig">
        <area-chart :data="data" :options="options" />
      </dashboard-layout>`,
});

const areaChartData = [
  ['2024-09-20', 1],
  ['2024-09-21', 3],
  ['2024-09-22', null],
  ['2024-09-23', 1],
  ['2024-09-24', 2],
  ['2024-09-25', null],
  ['2024-09-26', null],
  ['2024-09-27', 3],
  ['2024-09-28', 3],
  ['2024-09-29', 1],
  ['2024-09-30', null],
];

const defaultArgs = {
  data: [
    {
      data: areaChartData,
      name: 'Deployment frequency',
    },
  ],
  options: {
    decimalPlaces: 1,
  },
};

export const Default = Template.bind({});
Default.args = defaultArgs;

export const InDashboardPanel = WithDashboard.bind({});
InDashboardPanel.args = {
  ...defaultArgs,
  panelsConfig: [
    {
      id: '1',
      title: 'Panel #1',
      gridAttributes: {
        yPos: 0,
        xPos: 0,
        width: 12,
        height: 3,
      },
    },
  ],
};
