<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlDropdownDivider,
  GlDropdownText,
  GlSearchBoxByType,
  GlSprintf,
} from '@gitlab/ui';
import { I18N_AVAILABLE_AGENTS_DROPDOWN } from '../constants';

export default {
  name: 'AvailableAgentsDropdown',
  i18n: I18N_AVAILABLE_AGENTS_DROPDOWN,
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlDropdownText,
    GlSearchBoxByType,
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
      } else if (this.selectedAgent === null) {
        return this.$options.i18n.selectAgent;
      }

      return this.selectedAgent;
    },
    shouldRenderCreateButton() {
      return this.searchTerm && !this.availableAgents.includes(this.searchTerm);
    },
    filteredResults() {
      const lowerCasedSearchTerm = this.searchTerm.toLowerCase();
      return this.availableAgents.filter((resultString) =>
        resultString.toLowerCase().includes(lowerCasedSearchTerm),
      );
    },
  },
  methods: {
    selectAgent(agent) {
      this.$emit('agentSelected', agent);
      this.selectedAgent = agent;
      this.clearSearch();
    },
    isSelected(agent) {
      return this.selectedAgent === agent;
    },
    clearSearch() {
      this.searchTerm = '';
    },
    focusSearch() {
      this.$refs.searchInput.focusInput();
    },
    handleShow() {
      this.clearSearch();
      this.focusSearch();
    },
    onKeyEnter() {
      if (!this.searchTerm?.length) {
        return;
      }
      this.$refs.dropdown.hide();
      this.selectAgent(this.searchTerm);
    },
  },
};
</script>
<template>
  <gl-dropdown ref="dropdown" :text="dropdownText" :loading="isRegistering" @shown="handleShow">
    <template #header>
      <gl-search-box-by-type
        ref="searchInput"
        v-model.trim="searchTerm"
        @keydown.enter.stop.prevent="onKeyEnter"
      />
    </template>
    <gl-dropdown-item
      v-for="agent in filteredResults"
      :key="agent"
      :is-checked="isSelected(agent)"
      is-check-item
      @click="selectAgent(agent)"
    >
      {{ agent }}
    </gl-dropdown-item>
    <gl-dropdown-text v-if="!filteredResults.length" ref="noMatchingResults">{{
      $options.i18n.noResults
    }}</gl-dropdown-text>
    <template v-if="shouldRenderCreateButton">
      <gl-dropdown-divider />
      <gl-dropdown-item data-testid="create-config-button" @click="selectAgent(searchTerm)">
        <gl-sprintf :message="$options.i18n.createButton">
          <template #searchTerm>{{ searchTerm }}</template>
        </gl-sprintf>
      </gl-dropdown-item>
    </template>
  </gl-dropdown>
</template>
