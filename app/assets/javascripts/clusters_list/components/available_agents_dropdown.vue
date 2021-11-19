<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { I18N_AVAILABLE_AGENTS_DROPDOWN } from '../constants';

export default {
  name: 'AvailableAgentsDropdown',
  i18n: I18N_AVAILABLE_AGENTS_DROPDOWN,
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    isRegistering: {
      required: true,
      type: Boolean,
    },
    availableAgents: {
      required: true,
      type: Array,
    },
  },
  data() {
    return {
      selectedAgent: null,
    };
  },
  computed: {
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
  },
};
</script>
<template>
  <gl-dropdown :text="dropdownText" :loading="isRegistering">
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
