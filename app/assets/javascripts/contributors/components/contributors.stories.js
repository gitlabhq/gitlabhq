import { withVuexStore } from 'storybook_addons/vuex_store';
import { parsedData } from '../stores/getters';
import { generateRawData } from './stories_utils';
import Contributors from './contributors.vue';

export default {
  component: Contributors,
  title: 'contributors/contributors',
  decorators: [withVuexStore],
  args: {
    commitsPath: '/gitlab-org/gitlab/-/commits/master?ref_type=heads',
    endpoint: '/gitlab-org/gitlab/-/graphs/master?format=json&ref_type=heads',
    branch: 'main',
    projectId: '278964',
  },
};

const createStoryWithState = ({ state = {} }) => {
  return (args, { argTypes, createVuexStore }) => ({
    components: { Contributors },
    props: Object.keys(argTypes),
    template: '<contributors v-bind="$props" />',
    store: createVuexStore({
      state: {
        chartData: generateRawData(200, 8),
        loading: false,
        ...state,
      },
      getters: {
        showChart: () => true,
        parsedData,
      },
      actions: {
        fetchChartData: () => true,
      },
    }),
  });
};

const defaultState = {
  state: {},
};
export const Default = createStoryWithState(defaultState).bind({});

const noDataState = {
  state: {
    chartData: [],
  },
};
export const NoData = createStoryWithState(noDataState).bind({});

const isLoadingState = {
  state: {
    loading: true,
  },
};
export const IsLoading = createStoryWithState(isLoadingState).bind({});
