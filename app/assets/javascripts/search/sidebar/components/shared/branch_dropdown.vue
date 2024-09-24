<script>
import { GlIcon, GlCollapsibleListbox } from '@gitlab/ui';
import { debounce } from 'lodash';
import { s__ } from '~/locale';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { SEARCH_ICON } from '../../constants';

export default {
  name: 'BranchDropdown',
  components: {
    GlIcon,
    GlCollapsibleListbox,
  },
  props: {
    sourceBranches: {
      type: Array,
      required: true,
    },
    errors: {
      type: Array,
      required: false,
      default: () => [],
    },
    headerText: {
      type: String,
      required: true,
    },
    searchBranchText: {
      type: String,
      required: true,
    },
    selectedBranch: {
      type: String,
      required: false,
      default: '',
    },
    icon: {
      type: String,
      required: false,
      default: SEARCH_ICON,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  i18n: {
    noSearchResultsText: s__('GlobalSearch|No matching results'),
    noLoadResultsText: s__('GlobalSearch|No results found'),
  },
  data() {
    return {
      selectedRef: '',
      query: '',
    };
  },
  computed: {
    extendedToggleButtonClass() {
      return [
        {
          '!gl-shadow-inner-1-red-500': this.hasError,
          'gl-font-monospace': Boolean(this.selectedBranch),
        },
        'gl-mb-0',
      ];
    },
    isSearching() {
      return this.query.length > 0;
    },
    dropdownItems() {
      return this.isSearching ? this.searchResults : this.sourceBranches;
    },
    noResultsText() {
      return this.isSearching
        ? this.$options.i18n.noSearchResultsText
        : this.$options.i18n.noLoadResultsText;
    },
  },
  created() {
    this.debouncedSearch = debounce(this.search, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    onSearchBoxInput(searchQuery = '') {
      this.query = searchQuery?.trim();
      this.debouncedSearch();
    },
    search() {
      if (!this.query) {
        this.searchResults = [];
        return;
      }
      this.searchResults = this.sourceBranches.filter((branch) => branch.text.includes(this.query));
    },
    selectRef(ref) {
      this.$emit('selected', ref);
    },
  },
};
</script>

<template>
  <div>
    <gl-collapsible-listbox
      class="ref-selector gl-w-full"
      block
      searchable
      resetable
      :selected="selectedBranch"
      :header-text="s__('GlobalSearch|Source branch')"
      :items="dropdownItems"
      :no-results-text="noResultsText"
      :searching="isLoading"
      :search-placeholder="searchBranchText"
      :toggle-class="extendedToggleButtonClass"
      :toggle-text="searchBranchText"
      :icon="icon"
      :loading="isLoading"
      :reset-button-label="s__('GlobalSearch|Reset')"
      v-bind="$attrs"
      v-on="$listeners"
      @hidden="$emit('hide')"
      @search="onSearchBoxInput"
      @select="selectRef"
      @reset="$emit('reset')"
    >
      <template #list-item="{ item }">
        {{ item.text }}
      </template>
      <template #footer>
        <div
          v-for="errorMessage in errors"
          :key="errorMessage"
          data-testid="branch-dropdown-error-list"
          class="gl-mx-4 gl-my-3 gl-flex gl-items-start gl-text-red-500"
        >
          <gl-icon name="error" class="gl-mr-2 gl-mt-2 gl-shrink-0" />
          <span>{{ errorMessage }}</span>
        </div>
      </template>
    </gl-collapsible-listbox>
  </div>
</template>
