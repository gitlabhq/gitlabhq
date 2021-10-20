<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { I18N_AVAILABLE_AGENTS_DROPDOWN } from '../constants';
import agentConfigurations from '../graphql/queries/agent_configurations.query.graphql';

export default {
  name: 'AvailableAgentsDropdown',
  i18n: I18N_AVAILABLE_AGENTS_DROPDOWN,
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  inject: ['projectPath'],
  props: {
    isRegistering: {
      required: true,
      type: Boolean,
    },
  },
  apollo: {
    agents: {
      query: agentConfigurations,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update(data) {
        this.populateAvailableAgents(data);
      },
    },
  },
  data() {
    return {
      availableAgents: [],
      selectedAgent: null,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.agents.loading;
    },
    dropdownText() {
      if (this.isRegistering) {
        return this.$options.i18n.registeringAgent;
      } else if (this.selectedAgent === null) {
        return this.$options.i18n.selectAgent;
      }

      return this.selectedAgent;
    },
  },
  methods: {
    selectAgent(agent) {
      this.$emit('agentSelected', agent);
      this.selectedAgent = agent;
    },
    isSelected(agent) {
      return this.selectedAgent === agent;
    },
    populateAvailableAgents(data) {
      const installedAgents = data?.project?.clusterAgents?.nodes.map((agent) => agent.name) ?? [];
      const configuredAgents =
        data?.project?.agentConfigurations?.nodes.map((config) => config.agentName) ?? [];

      this.availableAgents = configuredAgents.filter((agent) => !installedAgents.includes(agent));
    },
  },
};
</script>
<template>
  <gl-dropdown :text="dropdownText" :loading="isLoading || isRegistering">
    <gl-dropdown-item
      v-for="agent in availableAgents"
      :key="agent"
      :is-checked="isSelected(agent)"
      is-check-item
      @click="selectAgent(agent)"
    >
      {{ agent }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
