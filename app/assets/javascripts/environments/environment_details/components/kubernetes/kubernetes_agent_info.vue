<script>
import { GlIcon, GlLink, GlSprintf, GlButton, GlModalDirective } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import ConnectToAgentModal from '~/clusters_list/components/connect_to_agent_modal.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { getAgentLastContact, getAgentStatus } from '~/clusters_list/clusters_util';
import { AGENT_STATUSES, CONNECT_MODAL_ID } from '~/clusters_list/constants';

export default {
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
    TimeAgoTooltip,
    GlButton,
    ConnectToAgentModal,
  },
  directives: {
    GlModalDirective,
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
    agentProjectPath() {
      return this.clusterAgent.project?.fullPath || '';
    },
  },
  AGENT_STATUSES,
  CONNECT_MODAL_ID,
};
</script>
<template>
  <div>
    <div class="gl-mb-4 gl-mt-2 gl-text-default">
      <gl-icon name="kubernetes-agent" variant="subtle" />
      <gl-link :href="clusterAgent.webPath" class="gl-mr-3">
        <gl-sprintf :message="s__('ClusterAgents|Agent ID #%{agentId}')"
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

    <gl-button
      v-gl-modal-directive="$options.CONNECT_MODAL_ID"
      category="secondary"
      variant="confirm"
      class="gl-mb-2"
      >{{ s__('ClusterAgents|Connect to agent') }}</gl-button
    >

    <connect-to-agent-modal
      :agent-id="clusterAgent.id"
      :project-path="agentProjectPath"
      :is-configured="true"
    />
  </div>
</template>
