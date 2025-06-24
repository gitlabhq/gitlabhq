<script>
import { GlLink, GlSkeletonLoader } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import aiCatalogAgentsQuery from '../graphql/ai_catalog_agents.query.graphql';
import { AI_CATALOG_AGENTS_SHOW_ROUTE } from '../router/constants';

export default {
  name: 'AiCatalogAgents',
  components: {
    GlLink,
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
  methods: {
    formatId(id) {
      return getIdFromGraphQLId(id);
    },
  },
  showRoute: AI_CATALOG_AGENTS_SHOW_ROUTE,
};
</script>
<template>
  <div>
    <div v-if="isLoading">
      <gl-skeleton-loader />
    </div>
    <div v-else>
      <!-- Replace this content with generic visualization component -->
      <ul v-for="agent in aiCatalogAgents" :key="agent.id">
        <li>
          <gl-link :to="{ name: $options.showRoute, params: { id: formatId(agent.id) } }">
            {{ agent.name }}
          </gl-link>
          <p>
            {{ agent.description }}
          </p>
        </li>
      </ul>
    </div>
  </div>
</template>
