<script>
import { GlDropdown, GlDropdownItem, GlDropdownDivider, GlSearchBoxByType } from '@gitlab/ui';
import { mapGetters } from 'vuex';
import { __, sprintf } from '~/locale';

export default {
  name: 'CiEnvironmentsDropdown',
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlSearchBoxByType,
  },
  props: {
    value: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      searchTerm: '',
    };
  },
  computed: {
    ...mapGetters(['joinedEnvironments']),
    composedCreateButtonLabel() {
      return sprintf(__('Create wildcard: %{searchTerm}'), { searchTerm: this.searchTerm });
    },
    shouldRenderCreateButton() {
      return this.searchTerm && !this.joinedEnvironments.includes(this.searchTerm);
    },
    filteredResults() {
      const lowerCasedSearchTerm = this.searchTerm.toLowerCase();
      return this.joinedEnvironments.filter((resultString) =>
        resultString.toLowerCase().includes(lowerCasedSearchTerm),
      );
    },
  },
  methods: {
    selectEnvironment(selected) {
      this.$emit('selectEnvironment', selected);
      this.searchTerm = '';
    },
    createClicked() {
      this.$emit('createClicked', this.searchTerm);
      this.searchTerm = '';
    },
    isSelected(env) {
      return this.value === env;
    },
    clearSearch() {
      this.searchTerm = '';
    },
  },
};
</script>
<template>
  <gl-dropdown :text="value" @show="clearSearch">
    <gl-search-box-by-type v-model.trim="searchTerm" data-testid="ci-environment-search" />
    <gl-dropdown-item
      v-for="environment in filteredResults"
      :key="environment"
      :is-checked="isSelected(environment)"
      is-check-item
      @click="selectEnvironment(environment)"
    >
      {{ environment }}
    </gl-dropdown-item>
    <gl-dropdown-item v-if="!filteredResults.length" ref="noMatchingResults">{{
      __('No matching results')
    }}</gl-dropdown-item>
    <template v-if="shouldRenderCreateButton">
      <gl-dropdown-divider />
      <gl-dropdown-item data-testid="create-wildcard-button" @click="createClicked">
        {{ composedCreateButtonLabel }}
      </gl-dropdown-item>
    </template>
  </gl-dropdown>
</template>
