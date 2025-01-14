import createMockApollo from 'helpers/mock_apollo_helper';
import { withVuexStore } from 'storybook_addons/vuex_store';
import filters from '~/vue_shared/components/filtered_search_bar/store/modules/filters';
import getProjects from '../../shared/graphql/projects.query.graphql';
import ValueStreamFilters from './value_stream_filters.vue';

export default {
  component: ValueStreamFilters,
  title: 'ee/analytics/cycle_analytics/components/value_stream_filters',
  decorators: [withVuexStore],
};

const defaultApolloProvider = createMockApollo([
  [
    getProjects,
    () => ({
      data: { group: { id: 'fake-groups', projects: { nodes: [] } } },
    }),
  ],
]);

const createStory = () => {
  return (args, { argTypes, createVuexStore }) => ({
    components: { ValueStreamFilters },
    apolloProvider: defaultApolloProvider,
    store: createVuexStore({
      modules: { filters },
    }),
    props: Object.keys(argTypes),
    template: `<value-stream-filters v-bind="$props" />`,
  });
};

const defaultArgs = {
  namespacePath: 'fake/namespace',
  groupPath: 'groups/fake/group',
};

export const Default = {
  render: createStory(),
  args: defaultArgs,
};
