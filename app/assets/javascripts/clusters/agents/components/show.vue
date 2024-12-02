<!-- eslint-disable vue/multi-word-component-names -->
<script>
import {
  GlAlert,
  GlBadge,
  GlKeysetPagination,
  GlLoadingIcon,
  GlSprintf,
  GlTab,
  GlTabs,
  GlButton,
  GlModalDirective,
} from '@gitlab/ui';
import { s__, __ } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { CONNECT_MODAL_ID } from '~/clusters_list/constants';
import ConnectToAgentModal from '~/clusters_list/components/connect_to_agent_modal.vue';
import { MAX_LIST_COUNT } from '../constants';
import getClusterAgentQuery from '../graphql/queries/get_cluster_agent.query.graphql';
import TokenTable from './token_table.vue';
import ActivityEvents from './activity_events_list.vue';
import IntegrationStatus from './integration_status.vue';

export default {
  i18n: {
    installedInfo: s__('ClusterAgents|Created by %{name} %{time}'),
    loadingError: s__('ClusterAgents|An error occurred while loading your agent'),
    tokens: s__('ClusterAgents|Access tokens'),
    unknownUser: s__('ClusterAgents|Unknown user'),
    activity: __('Activity'),
    connectButtonText: s__('ClusterAgents|Connect to %{agentName}'),
  },
  connectModalId: CONNECT_MODAL_ID,
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
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
    GlButton,
    TimeAgoTooltip,
    TokenTable,
    ActivityEvents,
    IntegrationStatus,
    ConnectToAgentModal,
  },
  directives: {
    GlModalDirective,
  },
  inject: ['agentName', 'projectPath'],
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
    isUserAccessConfigured() {
      return Boolean(this.clusterAgent?.userAccessAuthorizations);
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
    <header class="gl-flex gl-flex-wrap gl-items-center gl-justify-between">
      <h1>{{ agentName }}</h1>
      <gl-button
        v-gl-modal-directive="$options.connectModalId"
        :disabled="!clusterAgent"
        category="secondary"
        variant="confirm"
      >
        <gl-sprintf :message="$options.i18n.connectButtonText"
          ><template #agentName>{{ agentName }}</template></gl-sprintf
        >
      </gl-button>
    </header>

    <gl-loading-icon v-if="isLoading && clusterAgent == null" size="lg" class="gl-m-3" />

    <template v-else-if="clusterAgent">
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

      <integration-status
        :tokens="tokens"
        class="gl-border-t-1 gl-border-t-default gl-py-5 gl-border-t-solid"
      />

      <gl-tabs
        sync-active-tab-with-query-params
        lazy
        class="gl-border-t-1 gl-border-t-default gl-border-t-solid"
      >
        <gl-tab :title="$options.i18n.activity" query-param-value="activity">
          <activity-events :agent-name="agentName" :project-path="projectPath" />
        </gl-tab>

        <slot name="ee-security-tab" :cluster-agent-id="clusterAgent.id"></slot>

        <gl-tab query-param-value="tokens">
          <template #title>
            <span data-testid="cluster-agent-token-count">
              {{ $options.i18n.tokens }}

              <gl-badge v-if="tokenCount" class="gl-tab-counter-badge">{{ tokenCount }}</gl-badge>
            </span>
          </template>

          <gl-loading-icon v-if="isLoading" size="lg" class="gl-m-3" />

          <div v-else>
            <token-table :tokens="tokens" :cluster-agent-id="clusterAgent.id" :cursor="cursor" />

            <div v-if="showPagination" class="gl-mt-5 gl-flex gl-justify-center">
              <gl-keyset-pagination v-bind="tokenPageInfo" @prev="prevPage" @next="nextPage" />
            </div>
          </div>
        </gl-tab>

        <slot name="ee-workspaces-tab" :agent-name="agentName" :project-path="projectPath"></slot>
      </gl-tabs>

      <connect-to-agent-modal
        :agent-id="clusterAgent.id"
        :project-path="projectPath"
        :is-configured="isUserAccessConfigured"
      />
    </template>

    <gl-alert v-else variant="danger" :dismissible="false">
      {{ $options.i18n.loadingError }}
    </gl-alert>
  </section>
</template>
