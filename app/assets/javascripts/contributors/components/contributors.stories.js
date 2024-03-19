import { withVuexStore } from 'storybook_addons/vuex_store';
import { parsedData } from '../stores/getters';
import { generateRawData } from './stories_utils';
import Contributors from './contributors.vue';

export default {
  component: Contributors,
  title: 'ce/contributors/contributors',
  decorators: [withVuexStore],
  args: {
    commitsPath: '/gitlab-org/gitlab/-/commits/master?ref_type=heads',
    endpoint: '/gitlab-org/gitlab/-/graphs/master?format=json&ref_type=heads',
    branch: 'main',
    projectId: '278964',
    getSvgIconPathContent: () =>
      Promise.resolve(
        `path://M8 16A8 8 0 1 0 8 0a8 8 0 0 0 0 16zM6 3a1 1 0 0 1 1 1v8a1 1 0 1 1-2 0V4a1 1 0 0 1 1-1zm4 0a1 1 0 0 1 1 1v8a1 1 0 1 1-2 0V4a1 1 0 0 1 1-1z`,
      ),
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
