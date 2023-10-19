<script>
import { debounce, uniq } from 'lodash';
import { GlDropdownDivider, GlDropdownItem, GlCollapsibleListbox, GlSprintf } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { __, s__, sprintf } from '~/locale';
import { convertEnvironmentScope } from '../utils';
import { ENVIRONMENT_QUERY_LIMIT } from '../constants';

export default {
  name: 'CiEnvironmentsDropdown',
  components: {
    GlCollapsibleListbox,
    GlDropdownDivider,
    GlDropdownItem,
    GlSprintf,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    areEnvironmentsLoading: {
      type: Boolean,
      required: true,
    },
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
    isDropdownLoading() {
      return this.areEnvironmentsLoading && !this.isDropdownShown;
    },
    isDropdownSearching() {
      return this.areEnvironmentsLoading && this.isDropdownShown;
    },
    searchedEnvironments() {
      let filtered = this.environments;

      // If there is no search term, make sure to include *
      if (!this.searchTerm) {
        filtered = uniq([...filtered, '*']);
      }

      // add custom env scope if it matches the search term
      if (this.customEnvScope && this.customEnvScope.startsWith(this.searchTerm)) {
        filtered = uniq([...filtered, this.customEnvScope]);
      }

      return filtered.sort().map((environment) => ({
        value: environment,
        text: environment,
      }));
    },
    shouldRenderCreateButton() {
      return (
        this.searchTerm && ![...this.environments, this.customEnvScope].includes(this.searchTerm)
      );
    },
    shouldRenderDivider() {
      return !this.areEnvironmentsLoading;
    },
    environmentScopeLabel() {
      return convertEnvironmentScope(this.selectedEnvironmentScope);
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
    maxEnvsNote: s__(
      'CiVariable|Maximum of %{limit} environments listed. For more environments, enter a search query.',
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
    :toggle-text="environmentScopeLabel"
    @search="debouncedSearch"
    @select="selectEnvironment"
    @shown="toggleDropdownShown(true)"
    @hidden="toggleDropdownShown(false)"
  >
    <template #footer>
      <gl-dropdown-divider v-if="shouldRenderDivider" />
      <div data-testid="max-envs-notice">
        <gl-dropdown-item class="gl-list-style-none" disabled>
          <gl-sprintf :message="$options.i18n.maxEnvsNote" class="gl-font-sm">
            <template #limit>
              {{ $options.ENVIRONMENT_QUERY_LIMIT }}
            </template>
          </gl-sprintf>
        </gl-dropdown-item>
      </div>
      <div v-if="shouldRenderCreateButton">
        <!-- TODO: Rethink create wildcard button. https://gitlab.com/gitlab-org/gitlab/-/issues/396928 -->
        <gl-dropdown-item
          class="gl-list-style-none"
          data-testid="create-wildcard-button"
          @click="createEnvironmentScope"
        >
          {{ composedCreateButtonLabel }}
        </gl-dropdown-item>
      </div>
    </template>
  </gl-collapsible-listbox>
</template>
