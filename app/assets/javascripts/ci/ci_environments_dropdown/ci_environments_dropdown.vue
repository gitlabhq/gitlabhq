<script>
import { debounce, uniq } from 'lodash';
import { GlDropdownDivider, GlDropdownItem, GlCollapsibleListbox } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { convertEnvironmentScope } from './utils';
import {
  ALL_ENVIRONMENTS_OPTION,
  ENVIRONMENT_QUERY_LIMIT,
  NO_ENVIRONMENT_OPTION,
} from './constants';

/**
 * This is a shared component used in the CI Variables settings and the Secrets Management form.
 * See ~/ci/common/private/ci_environments_dropdown.js
 *
 * Use the following props to set certain behaviors:
 *
 * isEnvironmentRequired: If false, adds a "Not Applicable" option
 *
 * canCreateWildcard: Allows user to create wildcard environment scopes.
 * e.g. `review/*` means jobs with environment names starting with
 * `review/`
 */

export default {
  name: 'CiEnvironmentsDropdown',
  components: {
    GlCollapsibleListbox,
    GlDropdownDivider,
    GlDropdownItem,
  },
  props: {
    areEnvironmentsLoading: {
      type: Boolean,
      required: true,
    },
    canCreateWildcard: {
      type: Boolean,
      required: false,
      default: true,
    },
    environments: {
      type: Array,
      required: true,
    },
    isEnvironmentRequired: {
      type: Boolean,
      required: false,
      default: true,
    },
    placeholderText: {
      type: String,
      required: false,
      default: __('Select environment or create wildcard'),
    },
    selectedEnvironmentScope: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      customEnvScope: null,
      isDropdownShown: false,
      selectedEnvironment: '',
      searchTerm: '',
    };
  },
  computed: {
    composedCreateButtonLabel() {
      return sprintf(__('Create wildcard: %{searchTerm}'), { searchTerm: this.searchTerm });
    },
    environmentScopeLabel() {
      return convertEnvironmentScope(this.selectedEnvironmentScope);
    },
    isDropdownLoading() {
      return this.areEnvironmentsLoading && !this.isDropdownShown;
    },
    isDropdownSearching() {
      return this.areEnvironmentsLoading && this.isDropdownShown;
    },
    searchedEnvironments() {
      let filtered = this.sortedEnvironments;

      // add custom env scope if it matches the search term
      if (this.customEnvScope && this.customEnvScope.startsWith(this.searchTerm)) {
        filtered = uniq([this.customEnvScope, ...filtered]);
      }

      if (!this.searchTerm) {
        // Add Not Applicable (None) as the first option if isEnvironmentRequired is true
        if (!this.isEnvironmentRequired) {
          filtered = [NO_ENVIRONMENT_OPTION.type, ...filtered];
        }

        // If there is no search term, make sure to include *
        filtered = uniq([ALL_ENVIRONMENTS_OPTION.type, ...filtered]);
      }

      return filtered.map((environment) => ({
        value: environment,
        text: environment,
      }));
    },
    shouldRenderCreateButton() {
      if (!this.canCreateWildcard) {
        return false;
      }

      return (
        this.searchTerm?.includes('*') &&
        ![...this.environments, this.customEnvScope].includes(this.searchTerm)
      );
    },
    shouldRenderDivider() {
      return !this.areEnvironmentsLoading;
    },
    sortedEnvironments() {
      return [...this.environments].sort();
    },
    toggleText() {
      return this.environmentScopeLabel || this.placeholderText;
    },
  },
  methods: {
    debouncedSearch: debounce(function debouncedSearch(searchTerm) {
      const newSearchTerm = searchTerm.trim();
      this.searchTerm = newSearchTerm;
      this.$emit('search-environment-scope', newSearchTerm);
    }, 500),
    selectEnvironment(selected) {
      this.$emit('select-environment', selected);
      this.selectedEnvironment = selected;
    },
    createEnvironmentScope() {
      this.customEnvScope = this.searchTerm;
      this.selectEnvironment(this.searchTerm);
    },
    toggleDropdownShown(isShown) {
      this.isDropdownShown = isShown;
    },
  },
  ENVIRONMENT_QUERY_LIMIT,
  i18n: {
    searchQueryNote: s__(
      'CiVariable|Enter a search query to find more environments, or use * to create a wildcard.',
    ),
  },
};
</script>
<template>
  <gl-collapsible-listbox
    v-model="selectedEnvironment"
    block
    searchable
    :items="searchedEnvironments"
    :loading="isDropdownLoading"
    :searching="isDropdownSearching"
    :toggle-text="toggleText"
    @search="debouncedSearch"
    @select="selectEnvironment"
    @shown="toggleDropdownShown(true)"
    @hidden="toggleDropdownShown(false)"
  >
    <template #footer>
      <gl-dropdown-divider v-if="shouldRenderDivider" />
      <gl-dropdown-item class="gl-list-none" disabled data-testid="search-query-note">
        {{ $options.i18n.searchQueryNote }}
      </gl-dropdown-item>
      <div v-if="shouldRenderCreateButton">
        <!-- TODO: Rethink create wildcard button. https://gitlab.com/gitlab-org/gitlab/-/issues/396928 -->
        <gl-dropdown-item
          class="gl-list-none"
          data-testid="create-wildcard-button"
          @click="createEnvironmentScope"
        >
          {{ composedCreateButtonLabel }}
        </gl-dropdown-item>
      </div>
    </template>
  </gl-collapsible-listbox>
</template>
