<script>
import aiCatalogAgentsQuery from '../graphql/ai_catalog_agents.query.graphql';
import AiCatalogList from '../components/ai_catalog_list.vue';

export default {
  name: 'AiCatalogAgents',
  components: {
    AiCatalogList,
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
  <ai-catalog-list :is-loading="isLoading" :items="aiCatalogAgents" />
</template>
