import DashboardLayout from 'storybook_helpers/dashboards/dashboard_layout.vue';
import { UNITS } from '~/analytics/shared/constants';
import LineChart from './line_chart.vue';

export default {
  component: LineChart,
  title: 'analytics/analytics_dashboards/components/visualizations/line_chart',
};

const Template = (args, { argTypes }) => ({
  components: { LineChart, DashboardLayout },
  props: Object.keys(argTypes),
  template: `
  <div class="gl-h-48">
    <line-chart :data="data" :options="options" />
  </div>`,
});

const WithDashboard = (args, { argTypes }) => ({
  components: { LineChart, DashboardLayout },
  props: Object.keys(argTypes),
  template: `
      <dashboard-layout :panels="panelsConfig">
        <line-chart :data="data" :options="options" />
      </dashboard-layout>`,
});

const LineChartData = [
  ['Mon', 1184],
  ['Tue', 1346],
  ['Wed', 1035],
  ['Thu', 1226],
  ['Fri', 1421],
  ['Sat', 1347],
  ['Sun', 1035],
];

const defaultArgs = {
  data: [
    {
      data: LineChartData,
      name: 'Deployment frequency',
    },
  ],
  options: {
    xAxis: { type: 'category' },
    yAxis: { type: 'value' },
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

export const WithHumanizedTooltipValues = Template.bind({});
WithHumanizedTooltipValues.args = {
  data: defaultArgs.data,
  options: {
    ...defaultArgs.options,
    chartTooltip: {
      valueUnit: UNITS.PER_DAY,
    },
  },
};

export const WithCustomAxisFormatting = Template.bind({});
WithCustomAxisFormatting.args = {
  data: [
    {
      name: 'Code Suggestions',
      data: [
        ['Mon', 0.62],
        ['Tue', 0.68],
        ['Wed', 0.71],
        ['Thu', 0.66],
        ['Fri', 0.74],
      ],
    },
    {
      name: 'Duo Chat',
      data: [
        ['Mon', 0.81],
        ['Tue', 0.78],
        ['Wed', 0.83],
        ['Thu', 0.85],
        ['Fri', 0.8],
      ],
    },
  ],
  options: {
    xAxis: { type: 'category' },
    yAxis: { name: '% User retention', type: 'value', valueUnit: UNITS.PERCENT },
    chartTooltip: { valueUnit: UNITS.PERCENT },
  },
};
