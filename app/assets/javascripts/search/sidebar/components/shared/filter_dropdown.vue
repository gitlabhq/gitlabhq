<script>
import { GlIcon, GlCollapsibleListbox, GlAvatar } from '@gitlab/ui';
import { debounce } from 'lodash';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { s__ } from '~/locale';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

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
    toggle-class="gl-mb-0"
    :toggle-text="searchText"
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
      <span v-if="item.username" class="gl-flex gl-items-center">
        <div class="gl-relative gl-mr-3">
          <gl-avatar
            :size="32"
            :src="item.avatar_url"
            :entity-name="item.value"
            :alt="item.value"
          />
        </div>
        <span class="gl-flex gl-flex-col">
          <span class="gl-whitespace-nowrap gl-font-bold">{{ item.name }}</span>
          <span class="gl-text-subtle"> @{{ item.username }}</span>
        </span>
      </span>
      <span v-else>{{ item.text }}</span>
    </template>
    <template #footer>
      <div
        v-if="hasError"
        data-testid="branch-dropdown-error"
        class="gl-mx-4 gl-my-3 gl-flex gl-items-start gl-text-danger"
      >
        <gl-icon name="error" class="gl-mr-2 gl-mt-2 gl-shrink-0" />
        <span class="gl-max-w-full gl-break-all">{{ error }}</span>
      </div>
    </template>
  </gl-collapsible-listbox>
</template>
