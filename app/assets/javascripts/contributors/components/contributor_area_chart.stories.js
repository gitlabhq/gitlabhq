import { withVuexStore } from 'storybook_addons/vuex_store';
import { parsedData } from '../stores/getters';
import { generateRawData, getMasterChartOptions, getMasterChartData } from './stories_utils';
import ContributorAreaChart from './contributor_area_chart.vue';

const chartData = generateRawData(30, 4);

export default {
  component: ContributorAreaChart,
  title: 'contributors/contributor_area_chart',
  decorators: [withVuexStore],
  args: {
    data: getMasterChartData(parsedData({ chartData })),
    option: getMasterChartOptions(),
    height: 216,
  },
};

const createStory = () => {
  return (args, { argTypes }) => ({
    components: { ContributorAreaChart },
    props: Object.keys(argTypes),
    template: '<contributor-area-chart v-bind="$props" />',
  });
};

export const Default = createStory().bind({});

export const NoData = createStory().bind({});
NoData.args = {
  data: getMasterChartData(parsedData({ chartData: [] })),
  ...NoData.args,
};
