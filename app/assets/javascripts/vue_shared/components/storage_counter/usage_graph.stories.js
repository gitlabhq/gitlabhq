/* eslint-disable @gitlab/require-i18n-strings */
import '@gitlab/ui/dist/utility_classes.css';
import UsageGraph from './usage_graph.vue';

export default {
  component: UsageGraph,
  title: 'vue_shared/components/storage_counter/usage_graph',
};

const Template = (args, { argTypes }) => ({
  components: { UsageGraph },
  props: Object.keys(argTypes),
  template: '<usage-graph v-bind="$props" />',
});

export const Default = Template.bind({});
Default.argTypes = {
  rootStorageStatistics: {
    description: 'The statistics object with all its fields',
    type: { name: 'object', required: true },
    defaultValue: {
      buildArtifactsSize: 400000,
      pipelineArtifactsSize: 38000,
      lfsObjectsSize: 4800000,
      packagesSize: 3800000,
      repositorySize: 39000000,
      snippetsSize: 2000112,
      storageSize: 39930000,
      uploadsSize: 7000,
      wikiSize: 300000,
    },
  },
  limit: {
    description:
      'When a limit is set, users will see how much of their storage usage (limit) is used. In case the limit is 0 or the current usage exceeds the limit, it just renders the distribution',
    defaultValue: 0,
  },
};
