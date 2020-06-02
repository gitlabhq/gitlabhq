<script>
import {
  GlFilteredSearch,
  GlButtonGroup,
  GlButton,
  GlNewDropdown as GlDropdown,
  GlNewDropdownItem as GlDropdownItem,
  GlTooltipDirective,
} from '@gitlab/ui';

import { __ } from '~/locale';
import createFlash from '~/flash';

import RecentSearchesStore from '~/filtered_search/stores/recent_searches_store';
import RecentSearchesService from '~/filtered_search/services/recent_searches_service';
import RecentSearchesStorageKeys from 'ee_else_ce/filtered_search/recent_searches_storage_keys';

import { SortDirection } from './constants';

export default {
  components: {
    GlFilteredSearch,
    GlButtonGroup,
    GlButton,
    GlDropdown,
    GlDropdownItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    namespace: {
      type: String,
      required: true,
    },
    recentSearchesStorageKey: {
      type: String,
      required: false,
      default: '',
    },
    tokens: {
      type: Array,
      required: true,
    },
    sortOptions: {
      type: Array,
      required: true,
    },
    initialFilterValue: {
      type: Array,
      required: false,
      default: () => [],
    },
    initialSortBy: {
      type: String,
      required: false,
      default: '',
      validator: value => value === '' || /(_desc)|(_asc)/g.test(value),
    },
    searchInputPlaceholder: {
      type: String,
      required: true,
    },
  },
  data() {
    let selectedSortOption = this.sortOptions[0].sortDirection.descending;
    let selectedSortDirection = SortDirection.descending;

    // Extract correct sortBy value based on initialSortBy
    if (this.initialSortBy) {
      selectedSortOption = this.sortOptions
        .filter(
          sortBy =>
            sortBy.sortDirection.ascending === this.initialSortBy ||
            sortBy.sortDirection.descending === this.initialSortBy,
        )
        .pop();
      selectedSortDirection = this.initialSortBy.endsWith('_desc')
        ? SortDirection.descending
        : SortDirection.ascending;
    }

    return {
      initialRender: true,
      recentSearchesPromise: null,
      filterValue: this.initialFilterValue,
      selectedSortOption,
      selectedSortDirection,
    };
  },
  computed: {
    tokenSymbols() {
      return this.tokens.reduce(
        (tokenSymbols, token) => ({
          ...tokenSymbols,
          [token.type]: token.symbol,
        }),
        {},
      );
    },
    sortDirectionIcon() {
      return this.selectedSortDirection === SortDirection.ascending
        ? 'sort-lowest'
        : 'sort-highest';
    },
    sortDirectionTooltip() {
      return this.selectedSortDirection === SortDirection.ascending
        ? __('Sort direction: Ascending')
        : __('Sort direction: Descending');
    },
  },
  watch: {
    /**
     * GlFilteredSearch currently doesn't emit any event when
     * search field is cleared, but we still want our parent
     * component to know that filters were cleared and do
     * necessary data refetch, so this watcher is basically
     * a dirty hack/workaround to identify if filter input
     * was cleared. :(
     */
    filterValue(value) {
      const [firstVal] = value;
      if (
        !this.initialRender &&
        value.length === 1 &&
        firstVal.type === 'filtered-search-term' &&
        !firstVal.value.data
      ) {
        this.$emit('onFilter', []);
      }

      // Set initial render flag to false
      // as we don't want to emit event
      // on initial load when value is empty already.
      this.initialRender = false;
    },
  },
  created() {
    if (this.recentSearchesStorageKey) this.setupRecentSearch();
  },
  methods: {
    /**
     * Initialize service and store instances for
     * getting Recent Search functional.
     */
    setupRecentSearch() {
      this.recentSearchesService = new RecentSearchesService(
        `${this.namespace}-${RecentSearchesStorageKeys[this.recentSearchesStorageKey]}`,
      );

      this.recentSearchesStore = new RecentSearchesStore({
        isLocalStorageAvailable: RecentSearchesService.isAvailable(),
        allowedKeys: this.tokens.map(token => token.type),
      });

      this.recentSearchesPromise = this.recentSearchesService
        .fetch()
        .catch(error => {
          if (error.name === 'RecentSearchesServiceError') return undefined;

          createFlash(__('An error occurred while parsing recent searches'));

          // Gracefully fail to empty array
          return [];
        })
        .then(searches => {
          if (!searches) return;

          // Put any searches that may have come in before
          // we fetched the saved searches ahead of the already saved ones
          const resultantSearches = this.recentSearchesStore.setRecentSearches(
            this.recentSearchesStore.state.recentSearches.concat(searches),
          );
          this.recentSearchesService.save(resultantSearches);
        });
    },
    getRecentSearches() {
      return this.recentSearchesStore?.state.recentSearches;
    },
    handleSortOptionClick(sortBy) {
      this.selectedSortOption = sortBy;
      this.$emit('onSort', sortBy.sortDirection[this.selectedSortDirection]);
    },
    handleSortDirectionClick() {
      this.selectedSortDirection =
        this.selectedSortDirection === SortDirection.ascending
          ? SortDirection.descending
          : SortDirection.ascending;
      this.$emit('onSort', this.selectedSortOption.sortDirection[this.selectedSortDirection]);
    },
    handleFilterSubmit(filters) {
      if (this.recentSearchesStorageKey) {
        this.recentSearchesPromise
          .then(() => {
            if (filters.length) {
              const searchTokens = filters.map(filter => {
                // check filter was plain text search
                if (typeof filter === 'string') {
                  return filter;
                }
                // filter was a token.
                return `${filter.type}:${filter.value.operator}${this.tokenSymbols[filter.type]}${
                  filter.value.data
                }`;
              });

              const resultantSearches = this.recentSearchesStore.addRecentSearch(
                searchTokens.join(' '),
              );
              this.recentSearchesService.save(resultantSearches);
            }
          })
          .catch(() => {
            // https://gitlab.com/gitlab-org/gitlab-foss/issues/30821
          });
      }
      this.$emit('onFilter', filters);
    },
  },
};
</script>

<template>
  <div class="vue-filtered-search-bar-container d-flex">
    <gl-filtered-search
      v-model="filterValue"
      :placeholder="searchInputPlaceholder"
      :available-tokens="tokens"
      :history-items="getRecentSearches()"
      class="flex-grow-1"
      @submit="handleFilterSubmit"
    />
    <gl-button-group class="ml-2">
      <gl-dropdown :text="selectedSortOption.title" :right="true">
        <gl-dropdown-item
          v-for="sortBy in sortOptions"
          :key="sortBy.id"
          :is-check-item="true"
          :is-checked="sortBy.id === selectedSortOption.id"
          @click="handleSortOptionClick(sortBy)"
          >{{ sortBy.title }}</gl-dropdown-item
        >
      </gl-dropdown>
      <gl-button
        v-gl-tooltip
        :title="sortDirectionTooltip"
        :icon="sortDirectionIcon"
        @click="handleSortDirectionClick"
      />
    </gl-button-group>
  </div>
</template>
