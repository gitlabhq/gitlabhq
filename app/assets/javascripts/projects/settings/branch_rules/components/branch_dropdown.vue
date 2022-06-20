<script>
import { GlDropdown, GlDropdownItem, GlDropdownDivider, GlSearchBoxByType } from '@gitlab/ui';
import { createAlert } from '~/flash';
import { __, sprintf } from '~/locale';
import branchesQuery from '../queries/branches.query.graphql';

export const i18n = {
  fetchBranchesError: __('An error occurred while fetching branches.'),
  noMatch: __('No matching results'),
};

export default {
  i18n,
  name: 'BranchDropdown',
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlSearchBoxByType,
  },
  apollo: {
    branchNames: {
      query: branchesQuery,
      variables() {
        return {
          projectPath: this.projectPath,
          searchPattern: `*${this.searchTerm}*`,
        };
      },
      update({ project: { repository = {} } } = {}) {
        return repository.branchNames || [];
      },
      error(e) {
        createAlert({
          message: this.$options.i18n.fetchBranchesError,
          captureError: true,
          error: e,
        });
      },
    },
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    value: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      searchTerm: '',
      branchNames: [],
    };
  },
  computed: {
    createButtonLabel() {
      return sprintf(__('Create wildcard: %{searchTerm}'), { searchTerm: this.searchTerm });
    },
    shouldRenderCreateButton() {
      return this.searchTerm && !this.branchNames.includes(this.searchTerm);
    },
    isLoading() {
      return this.$apollo.queries.branchNames.loading;
    },
  },
  methods: {
    selectBranch(selected) {
      this.$emit('input', selected);
    },
    createWildcard() {
      this.$emit('createWildcard', this.searchTerm);
    },
    isSelected(branch) {
      return this.value === branch;
    },
  },
};
</script>
<template>
  <gl-dropdown :text="value || branchNames[0]">
    <gl-search-box-by-type
      v-model.trim="searchTerm"
      data-testid="branch-search"
      debounce="250"
      :is-loading="isLoading"
    />
    <gl-dropdown-item
      v-for="branch in branchNames"
      :key="branch"
      :is-checked="isSelected(branch)"
      is-check-item
      @click="selectBranch(branch)"
    >
      {{ branch }}
    </gl-dropdown-item>
    <gl-dropdown-item v-if="!branchNames.length && !isLoading" data-testid="no-data">{{
      $options.i18n.noMatch
    }}</gl-dropdown-item>
    <template v-if="shouldRenderCreateButton">
      <gl-dropdown-divider />
      <gl-dropdown-item data-testid="create-wildcard-button" @click="createWildcard">
        {{ createButtonLabel }}
      </gl-dropdown-item>
    </template>
  </gl-dropdown>
</template>
