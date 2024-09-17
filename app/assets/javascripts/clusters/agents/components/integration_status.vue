<script>
import { GlCollapse, GlButton, GlIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import { AGENT_STATUSES } from '~/clusters_list/constants';
import { getAgentLastContact, getAgentStatus } from '~/clusters_list/clusters_util';
import {
  INTEGRATION_STATUS_VALID_TOKEN,
  INTEGRATION_STATUS_NO_TOKEN,
  INTEGRATION_STATUS_RESTRICTED_CI_CD,
} from '../constants';
import AgentIntegrationStatusRow from './agent_integration_status_row.vue';

export default {
  components: {
    GlCollapse,
    GlButton,
    GlIcon,
    AgentIntegrationStatusRow,
  },
  i18n: {
    title: s__('ClusterAgents|Integration Status'),
  },
  AGENT_STATUSES,
  props: {
    tokens: {
      required: true,
      type: Array,
    },
  },
  data() {
    return {
      isVisible: false,
    };
  },
  computed: {
    chevronIcon() {
      return this.isVisible ? 'chevron-down' : 'chevron-right';
    },
    agentStatus() {
      const lastContact = getAgentLastContact(this.tokens);
      return getAgentStatus(lastContact);
    },
    integrationStatuses() {
      const statuses = [];

      if (this.agentStatus === 'active') {
        statuses.push(INTEGRATION_STATUS_VALID_TOKEN);
      }

      if (!this.tokens.length) {
        statuses.push(INTEGRATION_STATUS_NO_TOKEN);
      }

      statuses.push(INTEGRATION_STATUS_RESTRICTED_CI_CD);

      return statuses;
    },
  },
  methods: {
    toggleCollapse() {
      this.isVisible = !this.isVisible;
    },
  },
};
</script>

<template>
  <div>
    <gl-button
      :icon="chevronIcon"
      variant="link"
      size="small"
      class="gl-mr-3"
      @click="toggleCollapse"
    >
      {{ $options.i18n.title }} </gl-button
    ><span data-testid="agent-status">
      <gl-icon
        :name="$options.AGENT_STATUSES[agentStatus].icon"
        :class="$options.AGENT_STATUSES[agentStatus].class"
        class="gl-mr-2"
      />{{ $options.AGENT_STATUSES[agentStatus].name }}
    </span>
    <gl-collapse v-model="isVisible" class="gl-ml-5 gl-mt-5">
      <ul class="gl-mb-0 gl-list-none gl-pl-2">
        <agent-integration-status-row
          v-for="(status, index) in integrationStatuses"
          :key="index"
          :icon="status.icon"
          :icon-class="status.iconClass"
          :text="status.text"
          :help-url="status.helpUrl"
          :feature-name="status.featureName"
        />
      </ul>
    </gl-collapse>
  </div>
</template>
