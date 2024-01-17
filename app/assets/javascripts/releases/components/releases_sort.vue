<script>
import { GlSorting } from '@gitlab/ui';
import {
  ASCENDING_ORDER,
  DESCENDING_ORDER,
  SORT_OPTIONS,
  RELEASED_AT,
  CREATED_AT,
  RELEASED_AT_ASC,
  RELEASED_AT_DESC,
  CREATED_ASC,
  ALL_SORTS,
  SORT_MAP,
} from '../constants';

export default {
  name: 'ReleasesSort',
  components: {
    GlSorting,
  },
  props: {
    value: {
      type: String,
      required: true,
      validator: (sort) => ALL_SORTS.includes(sort),
    },
  },
  computed: {
    orderBy() {
      if (this.value === RELEASED_AT_ASC || this.value === RELEASED_AT_DESC) {
        return RELEASED_AT;
      }

      return CREATED_AT;
    },
    direction() {
      if (this.value === RELEASED_AT_ASC || this.value === CREATED_ASC) {
        return ASCENDING_ORDER;
      }

      return DESCENDING_ORDER;
    },
    sortOptions() {
      return SORT_OPTIONS;
    },
    sortText() {
      return this.sortOptions.find((s) => s.value === this.orderBy).text;
    },
    isDirectionAscending() {
      return this.direction === ASCENDING_ORDER;
    },
  },
  methods: {
    onDirectionChange() {
      const direction = this.isDirectionAscending ? DESCENDING_ORDER : ASCENDING_ORDER;
      this.emitInputEventIfChanged(this.orderBy, direction);
    },
    onSortItemClick(orderBy) {
      this.emitInputEventIfChanged(orderBy, this.direction);
    },
    emitInputEventIfChanged(orderBy, direction) {
      const newSort = SORT_MAP[orderBy][direction];
      if (newSort !== this.value) {
        this.$emit('input', SORT_MAP[orderBy][direction]);
      }
    },
  },
};
</script>

<template>
  <gl-sorting
    :text="sortText"
    :is-ascending="isDirectionAscending"
    :sort-options="sortOptions"
    :sort-by="orderBy"
    data-testid="releases-sort"
    @sortDirectionChange="onDirectionChange"
    @sortByChange="onSortItemClick"
  />
</template>
