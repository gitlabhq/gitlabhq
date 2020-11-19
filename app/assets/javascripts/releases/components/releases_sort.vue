<script>
import { GlSorting, GlSortingItem } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { ASCENDING_ODER, DESCENDING_ORDER, SORT_OPTIONS } from '../constants';

export default {
  name: 'ReleasesSort',
  components: {
    GlSorting,
    GlSortingItem,
  },
  computed: {
    ...mapState('list', {
      orderBy: state => state.sorting.orderBy,
      sort: state => state.sorting.sort,
    }),
    sortOptions() {
      return SORT_OPTIONS;
    },
    sortText() {
      const option = this.sortOptions.find(s => s.orderBy === this.orderBy);
      return option.label;
    },
    isSortAscending() {
      return this.sort === ASCENDING_ODER;
    },
  },
  methods: {
    ...mapActions('list', ['setSorting']),
    onDirectionChange() {
      const sort = this.isSortAscending ? DESCENDING_ORDER : ASCENDING_ODER;
      this.setSorting({ sort });
      this.$emit('sort:changed');
    },
    onSortItemClick(item) {
      this.setSorting({ orderBy: item });
      this.$emit('sort:changed');
    },
    isActiveSortItem(item) {
      return this.orderBy === item;
    },
  },
};
</script>

<template>
  <gl-sorting
    :text="sortText"
    :is-ascending="isSortAscending"
    data-testid="releases-sort"
    @sortDirectionChange="onDirectionChange"
  >
    <gl-sorting-item
      v-for="item in sortOptions"
      :key="item.orderBy"
      :active="isActiveSortItem(item.orderBy)"
      @click="onSortItemClick(item.orderBy)"
    >
      {{ item.label }}
    </gl-sorting-item>
  </gl-sorting>
</template>
