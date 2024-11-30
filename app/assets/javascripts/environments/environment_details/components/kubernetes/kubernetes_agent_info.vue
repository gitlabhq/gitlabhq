<script>
import { GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { getAgentLastContact, getAgentStatus } from '~/clusters_list/clusters_util';
import { AGENT_STATUSES } from '~/clusters_list/constants';
import { s__ } from '~/locale';

export default {
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
    TimeAgoTooltip,
  },
  props: {
    clusterAgent: {
      required: true,
      type: Object,
    },
  },
  computed: {
    agentLastContact() {
      return getAgentLastContact(this.clusterAgent.tokens.nodes);
    },
    agentStatus() {
      return getAgentStatus(this.agentLastContact);
    },
    agentId() {
      return getIdFromGraphQLId(this.clusterAgent.id);
    },
  },
  methods: {},
  i18n: {
    agentId: s__('ClusterAgents|Agent ID #%{agentId}'),
  },
  AGENT_STATUSES,
};
</script>
<template>
  <div class="gl-text-default">
    <gl-icon name="kubernetes-agent" variant="subtle" />
    <gl-link :href="clusterAgent.webPath" class="gl-mr-3">
      <gl-sprintf :message="$options.i18n.agentId"
        ><template #agentId>{{ agentId }}</template></gl-sprintf
      >
    </gl-link>
    <span data-testid="agent-status">
      <gl-icon
        :name="$options.AGENT_STATUSES[agentStatus].icon"
        :class="$options.AGENT_STATUSES[agentStatus].class"
      />
      {{ $options.AGENT_STATUSES[agentStatus].name }}
    </span>

    <span data-testid="agent-last-used-date">
      <time-ago-tooltip v-if="agentLastContact" :time="agentLastContact" />
    </span>
  </div>
</template>
