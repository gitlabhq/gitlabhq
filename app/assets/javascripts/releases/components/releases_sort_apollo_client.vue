<script>
import { GlSorting, GlSortingItem } from '@gitlab/ui';
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
  name: 'ReleasesSortApolloclient',
  components: {
    GlSorting,
    GlSortingItem,
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
      return this.sortOptions.find((s) => s.orderBy === this.orderBy).label;
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
    onSortItemClick(item) {
      this.emitInputEventIfChanged(item.orderBy, this.direction);
    },
    isActiveSortItem(item) {
      return this.orderBy === item.orderBy;
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
    data-testid="releases-sort"
    @sortDirectionChange="onDirectionChange"
  >
    <gl-sorting-item
      v-for="item of sortOptions"
      :key="item.orderBy"
      :active="isActiveSortItem(item)"
      @click="onSortItemClick(item)"
    >
      {{ item.label }}
    </gl-sorting-item>
  </gl-sorting>
</template>
