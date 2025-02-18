<script>
import { GlIcon, GlCollapsibleListbox, GlAvatar } from '@gitlab/ui';
import { debounce } from 'lodash';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { s__ } from '~/locale';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { SEARCH_ICON } from '../../constants';

export default {
  name: 'FilterDropdown',
  components: {
    GlIcon,
    GlCollapsibleListbox,
    GlAvatar,
  },
  props: {
    listData: {
      type: Array,
      required: true,
    },
    error: {
      type: String,
      required: false,
      default: '',
    },
    headerText: {
      type: String,
      required: true,
    },
    searchText: {
      type: String,
      required: true,
    },
    selectedItem: {
      type: String,
      required: false,
      default: '',
    },
    icon: {
      type: String,
      required: false,
      default: SEARCH_ICON,
    },
    hasApiSearch: {
      type: Boolean,
      required: false,
      default: false,
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
      query: '',
    };
  },
  computed: {
    extendedToggleButtonClass() {
      return [
        {
          '!gl-shadow-inner-1-red-500': this.hasError,
          'gl-font-monospace': Boolean(this.selectedItem),
        },
        'gl-mb-0',
      ];
    },
    isSearching() {
      return this.query.length > 0;
    },
    dropdownItems() {
      return this.isSearching && !this.hasApiSearch ? this.searchResults : this.listData;
    },
    noResultsText() {
      return this.isSearching
        ? this.$options.i18n.noSearchResultsText
        : this.$options.i18n.noLoadResultsText;
    },
    hasError() {
      return Boolean(this.error);
    },
  },
  created() {
    this.debouncedSearch = debounce(this.search, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    onSearchBoxInput(searchQuery = '') {
      if (this.hasApiSearch) {
        this.$emit('search', searchQuery);
        return;
      }

      this.query = searchQuery?.trim();
      this.debouncedSearch();
    },
    search() {
      if (!this.query) {
        this.searchResults = [];
        return;
      }
      this.searchResults = fuzzaldrinPlus.filter(this.listData, this.query, { key: ['text'] });
    },
    selectRef(selectedAuthorValue) {
      this.$emit('selected', selectedAuthorValue);
    },
    onHide() {
      if (!this.query || this.searchResults.length > 0) {
        this.$emit('hide');
        return;
      }
      this.$emit('selected', this.query);
      this.$emit('hide');
    },
  },
};
</script>

<template>
  <div>
    <gl-collapsible-listbox
      class="ref-selector gl-w-full gl-overflow-hidden"
      block
      searchable
      resetable
      :selected="selectedItem"
      :header-text="headerText"
      :items="dropdownItems"
      :no-results-text="noResultsText"
      :searching="isLoading"
      :search-placeholder="searchText"
      :toggle-class="extendedToggleButtonClass"
      :toggle-text="searchText"
      :icon="icon"
      :loading="isLoading"
      :reset-button-label="s__('GlobalSearch|Reset')"
      :is-check-centered="true"
      v-bind="$attrs"
      v-on="$listeners"
      @hidden="onHide"
      @search="onSearchBoxInput"
      @select="selectRef"
      @reset="$emit('reset')"
    >
      <template #list-item="{ item }">
        <span class="gl-flex gl-items-center">
          <gl-avatar
            :size="32"
            :entity-name="item.value"
            :src="item.avatar_url"
            :alt="item.value"
            class="gl-mr-3"
          />
          <span>{{ item.text }}</span>
        </span>
      </template>
      <template #footer>
        <div
          v-if="hasError"
          data-testid="branch-dropdown-error"
          class="gl-mx-4 gl-my-3 gl-flex gl-items-start gl-text-red-500"
        >
          <gl-icon name="error" class="gl-mr-2 gl-mt-2 gl-shrink-0" />
          <span class="gl-max-w-full gl-break-all">{{ error }}</span>
        </div>
      </template>
    </gl-collapsible-listbox>
  </div>
</template>
