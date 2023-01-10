<script>
import { GlDropdownDivider, GlDropdownItem, GlCollapsibleListbox } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { convertEnvironmentScope } from '../utils';

export default {
  name: 'CiEnvironmentsDropdown',
  components: {
    GlDropdownDivider,
    GlDropdownItem,
    GlCollapsibleListbox,
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
      selectedEnvironment: '',
      searchTerm: '',
    };
  },
  computed: {
    composedCreateButtonLabel() {
      return sprintf(__('Create wildcard: %{searchTerm}'), { searchTerm: this.searchTerm });
    },
    filteredEnvironments() {
      const lowerCasedSearchTerm = this.searchTerm.toLowerCase();

      return this.environments
        .filter((environment) => {
          return environment.toLowerCase().includes(lowerCasedSearchTerm);
        })
        .map((environment) => ({
          value: environment,
          text: environment,
        }));
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
      this.selectedEnvironment = selected;
    },
    createEnvironmentScope() {
      this.$emit('create-environment-scope', this.searchTerm);
      this.selectEnvironment(this.searchTerm);
    },
  },
};
</script>
<template>
  <gl-collapsible-listbox
    v-model="selectedEnvironment"
    searchable
    :items="filteredEnvironments"
    :toggle-text="environmentScopeLabel"
    @search="searchTerm = $event.trim()"
    @select="selectEnvironment"
  >
    <template v-if="shouldRenderCreateButton" #footer>
      <gl-dropdown-divider />
      <gl-dropdown-item data-testid="create-wildcard-button" @click="createEnvironmentScope">
        {{ composedCreateButtonLabel }}
      </gl-dropdown-item>
    </template>
  </gl-collapsible-listbox>
</template>
