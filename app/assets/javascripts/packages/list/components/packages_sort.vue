<script>
import { GlSorting, GlSortingItem } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { ASCENDING_ODER, DESCENDING_ORDER } from '../constants';
import getTableHeaders from '../utils';

export default {
  name: 'PackageSort',
  components: {
    GlSorting,
    GlSortingItem,
  },
  computed: {
    ...mapState({
      isGroupPage: state => state.config.isGroupPage,
      orderBy: state => state.sorting.orderBy,
      sort: state => state.sorting.sort,
    }),
    sortText() {
      const field = this.sortableFields.find(s => s.orderBy === this.orderBy);
      return field ? field.label : '';
    },
    sortableFields() {
      return getTableHeaders(this.isGroupPage);
    },
    isSortAscending() {
      return this.sort === ASCENDING_ODER;
    },
  },
  methods: {
    ...mapActions(['setSorting']),
    onDirectionChange() {
      const sort = this.isSortAscending ? DESCENDING_ORDER : ASCENDING_ODER;
      this.setSorting({ sort });
      this.$emit('sort:changed');
    },
    onSortItemClick(item) {
      this.setSorting({ orderBy: item });
      this.$emit('sort:changed');
    },
  },
};
</script>

<template>
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
</template>
