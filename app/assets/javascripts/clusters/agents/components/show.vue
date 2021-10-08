<script>
import {
  GlAlert,
  GlBadge,
  GlKeysetPagination,
  GlLoadingIcon,
  GlSprintf,
  GlTab,
  GlTabs,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { MAX_LIST_COUNT } from '../constants';
import getClusterAgentQuery from '../graphql/queries/get_cluster_agent.query.graphql';
import TokenTable from './token_table.vue';

export default {
  i18n: {
    installedInfo: s__('ClusterAgents|Created by %{name} %{time}'),
    loadingError: s__('ClusterAgents|An error occurred while loading your agent'),
    tokens: s__('ClusterAgents|Access tokens'),
    unknownUser: s__('ClusterAgents|Unknown user'),
  },
  apollo: {
    clusterAgent: {
      query: getClusterAgentQuery,
      variables() {
        return {
          agentName: this.agentName,
          projectPath: this.projectPath,
          ...this.cursor,
        };
      },
      update: (data) => data?.project?.clusterAgent,
      error() {
        this.clusterAgent = null;
      },
    },
  },
  components: {
    GlAlert,
    GlBadge,
    GlKeysetPagination,
    GlLoadingIcon,
    GlSprintf,
    GlTab,
    GlTabs,
    TimeAgoTooltip,
    TokenTable,
  },
  props: {
    agentName: {
      required: true,
      type: String,
    },
    projectPath: {
      required: true,
      type: String,
    },
  },
  data() {
    return {
      cursor: {
        first: MAX_LIST_COUNT,
        last: null,
      },
    };
  },
  computed: {
    createdAt() {
      return this.clusterAgent?.createdAt;
    },
    createdBy() {
      return this.clusterAgent?.createdByUser?.name || this.$options.i18n.unknownUser;
    },
    isLoading() {
      return this.$apollo.queries.clusterAgent.loading;
    },
    showPagination() {
      return this.tokenPageInfo.hasPreviousPage || this.tokenPageInfo.hasNextPage;
    },
    tokenCount() {
      return this.clusterAgent?.tokens?.count;
    },
    tokenPageInfo() {
      return this.clusterAgent?.tokens?.pageInfo || {};
    },
    tokens() {
      return this.clusterAgent?.tokens?.nodes || [];
    },
  },
  methods: {
    nextPage() {
      this.cursor = {
        first: MAX_LIST_COUNT,
        last: null,
        afterToken: this.tokenPageInfo.endCursor,
      };
    },
    prevPage() {
      this.cursor = {
        first: null,
        last: MAX_LIST_COUNT,
        beforeToken: this.tokenPageInfo.startCursor,
      };
    },
  },
};
</script>

<template>
  <section>
    <h2>{{ agentName }}</h2>

    <gl-loading-icon v-if="isLoading && clusterAgent == null" size="lg" class="gl-m-3" />

    <div v-else-if="clusterAgent">
      <p data-testid="cluster-agent-create-info">
        <gl-sprintf :message="$options.i18n.installedInfo">
          <template #name>
            {{ createdBy }}
          </template>

          <template #time>
            <time-ago-tooltip :time="createdAt" />
          </template>
        </gl-sprintf>
      </p>

      <gl-tabs>
        <gl-tab>
          <template #title>
            <span data-testid="cluster-agent-token-count">
              {{ $options.i18n.tokens }}

              <gl-badge v-if="tokenCount" size="sm" class="gl-tab-counter-badge">{{
                tokenCount
              }}</gl-badge>
            </span>
          </template>

          <gl-loading-icon v-if="isLoading" size="md" class="gl-m-3" />

          <div v-else>
            <TokenTable :tokens="tokens" />

            <div v-if="showPagination" class="gl-display-flex gl-justify-content-center gl-mt-5">
              <gl-keyset-pagination v-bind="tokenPageInfo" @prev="prevPage" @next="nextPage" />
            </div>
          </div>
        </gl-tab>
      </gl-tabs>
    </div>

    <gl-alert v-else variant="danger" :dismissible="false">
      {{ $options.i18n.loadingError }}
    </gl-alert>
  </section>
</template>
