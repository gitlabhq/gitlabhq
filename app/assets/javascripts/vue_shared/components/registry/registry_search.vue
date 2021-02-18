<script>
import { GlSorting, GlSortingItem, GlFilteredSearch } from '@gitlab/ui';

const ASCENDING_ORDER = 'asc';
const DESCENDING_ORDER = 'desc';

export default {
  components: {
    GlSorting,
    GlSortingItem,
    GlFilteredSearch,
  },
  props: {
    filter: {
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
        return this.filter;
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
  },
  methods: {
    onDirectionChange() {
      const sort = this.isSortAscending ? DESCENDING_ORDER : ASCENDING_ORDER;
      this.$emit('sorting:changed', { sort });
    },
    onSortItemClick(item) {
      this.$emit('sorting:changed', { orderBy: item });
    },
    clearSearch() {
      this.$emit('filter:changed', []);
      this.$emit('filter:submit');
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-p-5 gl-bg-gray-10 gl-border-solid gl-border-1 gl-border-gray-100">
    <gl-filtered-search
      v-model="internalFilter"
      class="gl-mr-4 gl-flex-fill-1"
      :placeholder="__('Filter results')"
      :available-tokens="tokens"
      @submit="$emit('filter:submit')"
      @clear="clearSearch"
    />
    <gl-sorting
      :text="sortText"
      :is-ascending="isSortAscending"
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
