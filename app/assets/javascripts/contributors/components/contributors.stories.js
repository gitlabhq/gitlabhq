import { pinia } from '~/pinia/instance';
import { useContributors } from '../stores';
import { generateRawData } from './stories_utils';
import Contributors from './contributors.vue';

export default {
  component: Contributors,
  title: 'contributors/contributors',
  args: {
    commitsPath: '/gitlab-org/gitlab/-/commits/master?ref_type=heads',
    endpoint: '/gitlab-org/gitlab/-/graphs/master?format=json&ref_type=heads',
    branch: 'main',
    projectId: '278964',
  },
};

const createStoryWithState = ({ state = {} }) => {
  return (args, { argTypes }) => {
    const store = useContributors(pinia);
    store.$reset();
    store.$patch({
      chartData: generateRawData(200, 8),
      loading: false,
      ...state,
    });
    store.fetchChartData = () => Promise.resolve(true);

    return {
      components: { Contributors },
      props: Object.keys(argTypes),
      pinia,
      template: '<contributors v-bind="$props" />',
    };
  };
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
