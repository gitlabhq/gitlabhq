<script>
import { cloneDeep } from 'lodash';
import { __ } from '~/locale';
import FilteredSearch from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import { searchValidator } from '~/runner/runner_search_utils';
import { CREATED_DESC, CREATED_ASC, CONTACTED_DESC, CONTACTED_ASC } from '../constants';

const sortOptions = [
  {
    id: 1,
    title: __('Created date'),
    sortDirection: {
      descending: CREATED_DESC,
      ascending: CREATED_ASC,
    },
  },
  {
    id: 2,
    title: __('Last contact'),
    sortDirection: {
      descending: CONTACTED_DESC,
      ascending: CONTACTED_ASC,
    },
  },
];

export default {
  components: {
    FilteredSearch,
  },
  props: {
    value: {
      type: Object,
      required: true,
      validator: searchValidator,
    },
    tokens: {
      type: Array,
      required: false,
      default: () => [],
    },
    namespace: {
      type: String,
      required: true,
    },
  },
  data() {
    // filtered_search_bar_root.vue may mutate the initial
    // filters. Use `cloneDeep` to prevent those mutations
    // from affecting this component
    const { filters, sort } = cloneDeep(this.value);
    return {
      initialFilterValue: filters,
      initialSortBy: sort,
    };
  },
  computed: {
    validTokens() {
      // Some filters are only available in EE
      // EE-only tokens are represented by `null` or `undefined`
      // values when in CE
      return this.tokens.filter(Boolean);
    },
  },
  methods: {
    onFilter(filters) {
      // Apply new filters, from page 1
      this.$emit('input', {
        ...this.value,
        filters,
        pagination: { page: 1 },
      });
    },
    onSort(sort) {
      // Apply new sort, from page 1
      this.$emit('input', {
        ...this.value,
        sort,
        pagination: { page: 1 },
      });
    },
  },
  sortOptions,
};
</script>
<template>
  <filtered-search
    class="gl-bg-gray-10 gl-p-5 gl-border-solid gl-border-gray-100 gl-border-0 gl-border-t-1 gl-border-b-1"
    v-bind="$attrs"
    :namespace="namespace"
    recent-searches-storage-key="runners-search"
    :sort-options="$options.sortOptions"
    :initial-filter-value="initialFilterValue"
    :tokens="validTokens"
    :initial-sort-by="initialSortBy"
    :search-input-placeholder="__('Search or filter results...')"
    data-testid="runners-filtered-search"
    @onFilter="onFilter"
    @onSort="onSort"
  />
</template>
