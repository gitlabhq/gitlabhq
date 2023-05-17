<script>
import { GlSorting, GlSortingItem, GlFilteredSearch } from '@gitlab/ui';
import { SORT_DIRECTION_UI } from '~/search/sort/constants';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';

const ASCENDING_ORDER = 'asc';
const DESCENDING_ORDER = 'desc';

export default {
  components: {
    GlSorting,
    GlSortingItem,
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
        acc[curr.type] = '';
        return acc;
      }, {});
    },
    sortDirectionData() {
      return this.isSortAscending ? SORT_DIRECTION_UI.asc : SORT_DIRECTION_UI.desc;
    },
  },
  methods: {
    generateQueryData({ sorting = {}, filter = [] } = {}) {
      // Ensure that we clean up the query when we remove a token from the search
      const result = { ...this.baselineQueryStringFilters, ...sorting, search: [] };

      filter.forEach((f) => {
        if (f.type === FILTERED_SEARCH_TERM) {
          result.search.push(f.value.data);
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
  <div
    class="gl-md-display-flex gl-p-5 gl-bg-gray-10 gl-border-solid gl-border-1 gl-border-gray-100"
  >
    <!-- `gl-w-full gl-md-w-15` forces fixed width needed to prevent
    filtered component to grow beyond available width -->
    <gl-filtered-search
      v-model="internalFilter"
      class="gl-w-full gl-md-w-15 gl-mr-4 gl-flex-grow-1"
      :placeholder="__('Filter results')"
      :available-tokens="tokens"
      @submit="submitSearch"
      @clear="clearSearch"
    />
    <gl-sorting
      data-testid="registry-sort-dropdown"
      class="gl-mt-3 gl-md-mt-0 gl-w-full gl-md-w-auto"
      dropdown-class="gl-w-full"
      dropdown-toggle-class="gl-inset-border-1-gray-400!"
      sort-direction-toggle-class="gl-inset-border-1-gray-400!"
      :text="sortText"
      :is-ascending="isSortAscending"
      :sort-direction-tool-tip="sortDirectionData.tooltip"
      @sortDirectionChange="onDirectionChange"
    >
      <gl-sorting-item
        v-for="item in sortableFields"
        ref="packageListSortItem"
        :key="item.orderBy"
        @click="onSortItemClick(item.orderBy)"
      >
        {{ item.label }}
      </gl-sorting-item>
    </gl-sorting>
  </div>
</template>
