<script>
import { GlDropdown, GlDropdownItem, GlDropdownDivider, GlSearchBoxByType } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { convertEnvironmentScope } from '../utils';

export default {
  name: 'CiEnvironmentsDropdown',
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlSearchBoxByType,
  },
  props: {
    environments: {
      type: Array,
      required: true,
    },
    selectedEnvironmentScope: {
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
    composedCreateButtonLabel() {
      return sprintf(__('Create wildcard: %{searchTerm}'), { searchTerm: this.searchTerm });
    },
    filteredEnvironments() {
      const lowerCasedSearchTerm = this.searchTerm.toLowerCase();
      return this.environments.filter((environment) => {
        return environment.toLowerCase().includes(lowerCasedSearchTerm);
      });
    },
    shouldRenderCreateButton() {
      return this.searchTerm && !this.environments.includes(this.searchTerm);
    },
    environmentScopeLabel() {
      return convertEnvironmentScope(this.selectedEnvironmentScope);
    },
  },
  methods: {
    selectEnvironment(selected) {
      this.$emit('select-environment', selected);
      this.clearSearch();
    },
    convertEnvironmentScopeValue(scope) {
      return convertEnvironmentScope(scope);
    },
    createEnvironmentScope() {
      this.$emit('create-environment-scope', this.searchTerm);
      this.selectEnvironment(this.searchTerm);
    },
    isSelected(env) {
      return this.selectedEnvironmentScope === env;
    },
    clearSearch() {
      this.searchTerm = '';
    },
  },
};
</script>
<template>
  <gl-dropdown :text="environmentScopeLabel" @show="clearSearch">
    <gl-search-box-by-type v-model.trim="searchTerm" data-testid="ci-environment-search" />
    <gl-dropdown-item
      v-for="environment in filteredEnvironments"
      :key="environment"
      :is-checked="isSelected(environment)"
      is-check-item
      @click="selectEnvironment(environment)"
    >
      {{ convertEnvironmentScopeValue(environment) }}
    </gl-dropdown-item>
    <gl-dropdown-item v-if="!filteredEnvironments.length" ref="noMatchingResults">{{
      __('No matching results')
    }}</gl-dropdown-item>
    <template v-if="shouldRenderCreateButton">
      <gl-dropdown-divider />
      <gl-dropdown-item data-testid="create-wildcard-button" @click="createEnvironmentScope">
        {{ composedCreateButtonLabel }}
      </gl-dropdown-item>
    </template>
  </gl-dropdown>
</template>
