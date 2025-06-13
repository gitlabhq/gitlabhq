<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import userWorkflowsQuery from '../graphql/user_workflows.query.graphql';

export default {
  name: 'AiCatalogIndex',
  components: {
    GlSkeletonLoader,
  },
  apollo: {
    userWorkflows: {
      query: userWorkflowsQuery,
      update: (data) => data.currentUser.workflows.nodes,
    },
  },
  data() {
    return {
      userWorkflows: [],
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.userWorkflows.loading;
    },
  },
};
</script>
<template>
  <div>
    <h1>{{ s__('AI|AI Catalog') }}</h1>
    <div v-if="isLoading">
      <gl-skeleton-loader />
    </div>
    <div v-else>
      <div v-for="workflow in userWorkflows" :key="workflow.id">
        <p>{{ workflow.name }}</p>
        <p>{{ workflow.type }}</p>
      </div>
    </div>
  </div>
</template>
