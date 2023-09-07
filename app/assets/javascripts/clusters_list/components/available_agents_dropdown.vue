<script>
import { GlCollapsibleListbox, GlButton, GlSprintf } from '@gitlab/ui';
import { I18N_AVAILABLE_AGENTS_DROPDOWN } from '../constants';

export default {
  name: 'AvailableAgentsDropdown',
  i18n: I18N_AVAILABLE_AGENTS_DROPDOWN,
  components: {
    GlCollapsibleListbox,
    GlButton,
    GlSprintf,
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
      searchTerm: '',
    };
  },
  computed: {
    dropdownText() {
      if (this.isRegistering) {
        return this.$options.i18n.registeringAgent;
      }
      if (this.selectedAgent === null) {
        return this.$options.i18n.selectAgent;
      }

      return this.selectedAgent;
    },
    dropdownItems() {
      return this.availableAgents.map((agent) => {
        return {
          value: agent,
          text: agent,
        };
      });
    },
    shouldRenderCreateButton() {
      return this.searchTerm && !this.availableAgents.includes(this.searchTerm);
    },
    filteredResults() {
      const lowerCasedSearchTerm = this.searchTerm.toLowerCase();
      return this.dropdownItems.filter((item) =>
        item.value.toLowerCase().includes(lowerCasedSearchTerm),
      );
    },
  },
  methods: {
    selectAgent(agent) {
      this.$emit('agentSelected', agent);
      this.selectedAgent = agent;
    },
    onKeyEnter() {
      if (!this.searchTerm?.length) {
        return;
      }
      this.selectAgent(this.searchTerm);
    },
    searchAgent(searchQuery) {
      this.searchTerm = searchQuery;
    },
  },
};
</script>
<template>
  <div @keydown.enter.stop.prevent="onKeyEnter">
    <gl-collapsible-listbox
      v-model="selectedAgent"
      class="gl-w-full"
      toggle-class="select-agent-dropdown"
      :items="filteredResults"
      :toggle-text="dropdownText"
      :loading="isRegistering"
      :searchable="true"
      :no-results-text="$options.i18n.noResults"
      @search="searchAgent"
      @select="selectAgent"
    >
      <template v-if="shouldRenderCreateButton" #footer>
        <gl-button
          category="tertiary"
          class="gl-justify-content-start! gl-border-t-1! gl-border-t-solid gl-border-t-gray-200 gl-pl-7! gl-rounded-top-left-none! gl-rounded-top-right-none!"
          :class="{ 'gl-mt-3': !filteredResults.length }"
          @click="selectAgent(searchTerm)"
        >
          <gl-sprintf :message="$options.i18n.createButton">
            <template #searchTerm>{{ searchTerm }}</template>
          </gl-sprintf>
        </gl-button>
      </template>
    </gl-collapsible-listbox>
  </div>
</template>
