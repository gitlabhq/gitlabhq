<script>
import { GlSorting, GlFilteredSearch } from '@gitlab/ui';
import { SORT_DIRECTION_UI } from '~/search/sort/constants';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';

const ASCENDING_ORDER = 'asc';
const DESCENDING_ORDER = 'desc';

export default {
  components: {
    GlSorting,
    GlFilteredSearch,
  },
  props: {
    filters: {
      type: Array,
      required: true,
    },
    sorting: {
      type: Object,
      required: true,
    },
    tokens: {
      type: Array,
      required: false,
      default: () => [],
    },
    sortableFields: {
      type: Array,
      required: true,
    },
  },
  computed: {
    internalFilter: {
      get() {
        return this.filters;
      },
      set(value) {
        this.$emit('filter:changed', value);
      },
    },
    sortText() {
      const field = this.sortableFields.find((s) => s.orderBy === this.sorting.orderBy);
      return field ? field.label : '';
    },
    isSortAscending() {
      return this.sorting.sort === ASCENDING_ORDER;
    },
    baselineQueryStringFilters() {
      return this.tokens.reduce((acc, curr) => {
        acc[curr.type] = null;
        return acc;
      }, {});
    },
    sortDirectionData() {
      return this.isSortAscending ? SORT_DIRECTION_UI.asc : SORT_DIRECTION_UI.desc;
    },
    sortOptions() {
      return this.sortableFields.map(({ orderBy, label }) => ({ text: label, value: orderBy }));
    },
  },
  methods: {
    generateQueryData({ sorting = {}, filter = [] } = {}) {
      // Ensure that we clean up the query when we remove a token from the search
      const result = {
        ...this.baselineQueryStringFilters,
        ...sorting,
        search: null,
        after: null,
        before: null,
      };

      filter.forEach((f) => {
        if (f.type === FILTERED_SEARCH_TERM) {
          const value = f.value.data?.trim();
          if (!value) return;

          if (Array.isArray(result.search)) {
            result.search.push(value);
          } else {
            result.search = [value];
          }
        } else {
          result[f.type] = f.value.data;
        }
      });

      return result;
    },
    onDirectionChange() {
      const sort = this.isSortAscending ? DESCENDING_ORDER : ASCENDING_ORDER;
      const newQueryString = this.generateQueryData({
        sorting: { ...this.sorting, sort },
        filter: this.filters,
      });
      this.$emit('sorting:changed', { sort });
      this.$emit('query:changed', newQueryString);
    },
    onSortItemClick(item) {
      const newQueryString = this.generateQueryData({
        sorting: { ...this.sorting, orderBy: item },
        filter: this.filters,
      });
      this.$emit('sorting:changed', { orderBy: item });
      this.$emit('query:changed', newQueryString);
    },
    submitSearch() {
      const newQueryString = this.generateQueryData({
        sorting: this.sorting,
        filter: this.filters,
      });
      this.$emit('filter:submit');
      this.$emit('query:changed', newQueryString);
    },
    clearSearch() {
      const newQueryString = this.generateQueryData({
        sorting: this.sorting,
      });

      this.$emit('filter:changed', []);
      this.$emit('filter:submit');
      this.$emit('query:changed', newQueryString);
    },
  },
};
</script>

<template>
  <div class="row-content-block gl-flex gl-flex-col gl-gap-3 md:gl-flex-row">
    <gl-filtered-search
      v-model="internalFilter"
      class="gl-min-w-0 gl-grow"
      :placeholder="__('Filter results')"
      :available-tokens="tokens"
      :search-text-option-label="__('Search for this text')"
      terms-as-tokens
      @submit="submitSearch"
      @clear="clearSearch"
    />
    <gl-sorting
      data-testid="registry-sort-dropdown"
      dropdown-class="gl-w-full"
      block
      :text="sortText"
      :is-ascending="isSortAscending"
      :sort-direction-tool-tip="sortDirectionData.tooltip"
      :sort-options="sortOptions"
      :sort-by="sorting.orderBy"
      @sortDirectionChange="onDirectionChange"
      @sortByChange="onSortItemClick"
    />
  </div>
</template>
