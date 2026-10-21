import { pinia } from '~/pinia/instance';
import { useContributors } from '../stores';
import { generateRawData, getMasterChartOptions, getMasterChartData } from './stories_utils';
import ContributorAreaChart from './contributor_area_chart.vue';

const chartData = generateRawData(30, 4);

const getParsedData = (data) => {
  const store = useContributors(pinia);
  store.chartData = data;
  return store.parsedData;
};

export default {
  component: ContributorAreaChart,
  title: 'contributors/contributor_area_chart',
  args: {
    data: getMasterChartData(getParsedData(chartData)),
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
  data: getMasterChartData(getParsedData([])),
  ...NoData.args,
};
