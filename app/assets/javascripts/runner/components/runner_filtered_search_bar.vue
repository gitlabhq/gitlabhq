<script>
import { cloneDeep } from 'lodash';
import { __ } from '~/locale';
import FilteredSearch from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
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
      validator(val) {
        return Array.isArray(val?.filters) && typeof val?.sort === 'string';
      },
    },
    namespace: {
      type: String,
      required: true,
    },
  },
  data() {
    // filtered_search_bar_root.vue may mutate the inital
    // filters. Use `cloneDeep` to prevent those mutations
    //  from affecting this component
    const { filters, sort } = cloneDeep(this.value);
    return {
      initialFilterValue: filters,
      initialSortBy: sort,
    };
  },
  methods: {
    onFilter(filters) {
      const { sort } = this.value;

      this.$emit('input', {
        filters,
        sort,
        pagination: { page: 1 },
      });
    },
    onSort(sort) {
      const { filters } = this.value;

      this.$emit('input', {
        filters,
        sort,
        pagination: { page: 1 },
      });
    },
  },
  sortOptions,
};
</script>
<template>
  <div>
    <filtered-search
      v-bind="$attrs"
      :namespace="namespace"
      recent-searches-storage-key="runners-search"
      :sort-options="$options.sortOptions"
      :initial-filter-value="initialFilterValue"
      :initial-sort-by="initialSortBy"
      :search-input-placeholder="__('Search or filter results...')"
      data-testid="runners-filtered-search"
      @onFilter="onFilter"
      @onSort="onSort"
    />
    <div class="gl-text-right" data-testid="runner-count">
      <slot name="runner-count"></slot>
    </div>
  </div>
</template>
