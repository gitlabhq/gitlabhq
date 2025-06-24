<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import aiCatalogAgentsQuery from '../graphql/ai_catalog_agents.query.graphql';

export default {
  name: 'AiCatalogAgents',
  components: {
    GlSkeletonLoader,
  },
  apollo: {
    aiCatalogAgents: {
      query: aiCatalogAgentsQuery,
      update: (data) => data.aiCatalogAgents.nodes,
    },
  },
  data() {
    return {
      aiCatalogAgents: [],
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.aiCatalogAgents.loading;
    },
  },
};
</script>
<template>
  <div>
    <div v-if="isLoading">
      <gl-skeleton-loader />
    </div>
    <div v-else>
      <!-- Replace this content with generic visualization component -->
      <div v-for="agent in aiCatalogAgents" :key="agent.id">
        <p>{{ agent.name }}</p>
        <p>{{ agent.description }}</p>
      </div>
    </div>
  </div>
</template>
