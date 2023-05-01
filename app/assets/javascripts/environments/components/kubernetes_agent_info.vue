<script>
import { GlIcon, GlLink, GlSprintf, GlLoadingIcon, GlAlert } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { getAgentLastContact, getAgentStatus } from '~/clusters_list/clusters_util';
import { AGENT_STATUSES } from '~/clusters_list/constants';
import { s__ } from '~/locale';
import getK8sClusterAgentQuery from '../graphql/queries/k8s_cluster_agent.query.graphql';

export default {
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
    GlLoadingIcon,
    TimeAgoTooltip,
    GlAlert,
  },
  props: {
    agentName: {
      required: true,
      type: String,
    },
    agentId: {
      required: true,
      type: String,
    },
    agentProjectPath: {
      required: true,
      type: String,
    },
  },
  apollo: {
    clusterAgent: {
      query: getK8sClusterAgentQuery,
      variables() {
        return {
          agentName: this.agentName,
          projectPath: this.agentProjectPath,
        };
      },
      update: (data) => data?.project?.clusterAgent,
      error() {
        this.clusterAgent = null;
      },
    },
  },
  data() {
    return {
      clusterAgent: null,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.clusterAgent.loading;
    },
    agentLastContact() {
      return getAgentLastContact(this.clusterAgent.tokens.nodes);
    },
    agentStatus() {
      return getAgentStatus(this.agentLastContact);
    },
  },
  methods: {},
  i18n: {
    loadingError: s__('ClusterAgents|An error occurred while loading your agent'),
    agentId: s__('ClusterAgents|Agent ID #%{agentId}'),
    neverConnectedText: s__('ClusterAgents|Never'),
  },
  AGENT_STATUSES,
};
</script>
<template>
  <gl-loading-icon v-if="isLoading" inline />
  <div v-else-if="clusterAgent" class="gl-text-gray-900">
    <gl-icon name="kubernetes-agent" class="gl-text-gray-500" />
    <gl-link :href="clusterAgent.webPath" class="gl-mr-3">
      <gl-sprintf :message="$options.i18n.agentId"
        ><template #agentId>{{ agentId }}</template></gl-sprintf
      >
    </gl-link>
    <span class="gl-mr-3" data-testid="agent-status">
      <gl-icon
        :name="$options.AGENT_STATUSES[agentStatus].icon"
        :class="$options.AGENT_STATUSES[agentStatus].class"
      />
      {{ $options.AGENT_STATUSES[agentStatus].name }}
    </span>

    <span data-testid="agent-last-used-date">
      <gl-icon name="calendar" />
      <time-ago-tooltip v-if="agentLastContact" :time="agentLastContact" />
      <span v-else>{{ $options.i18n.neverConnectedText }}</span>
    </span>
  </div>

  <gl-alert v-else variant="danger" :dismissible="false">
    {{ $options.i18n.loadingError }}
  </gl-alert>
</template>
