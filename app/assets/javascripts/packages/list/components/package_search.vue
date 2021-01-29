<script>
import { GlSorting, GlSortingItem, GlFilteredSearch } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { __, s__ } from '~/locale';
import PackageTypeToken from './tokens/package_type_token.vue';
import { ASCENDING_ODER, DESCENDING_ORDER } from '../constants';
import getTableHeaders from '../utils';

export default {
  components: {
    GlSorting,
    GlSortingItem,
    GlFilteredSearch,
  },
  computed: {
    ...mapState({
      isGroupPage: (state) => state.config.isGroupPage,
      orderBy: (state) => state.sorting.orderBy,
      sort: (state) => state.sorting.sort,
      filter: (state) => state.filter,
    }),
    internalFilter: {
      get() {
        return this.filter;
      },
      set(value) {
        this.setFilter(value);
      },
    },
    sortText() {
      const field = this.sortableFields.find((s) => s.orderBy === this.orderBy);
      return field ? field.label : '';
    },
    sortableFields() {
      return getTableHeaders(this.isGroupPage);
    },
    isSortAscending() {
      return this.sort === ASCENDING_ODER;
    },
    tokens() {
      return [
        {
          type: 'type',
          icon: 'package',
          title: s__('PackageRegistry|Type'),
          unique: true,
          token: PackageTypeToken,
          operators: [{ value: '=', description: __('is'), default: 'true' }],
        },
      ];
    },
  },
  methods: {
    ...mapActions(['setSorting', 'setFilter']),
    onDirectionChange() {
      const sort = this.isSortAscending ? DESCENDING_ORDER : ASCENDING_ODER;
      this.setSorting({ sort });
      this.$emit('sort:changed');
    },
    onSortItemClick(item) {
      this.setSorting({ orderBy: item });
      this.$emit('sort:changed');
    },
    clearSearch() {
      this.setFilter([]);
      this.$emit('filter:changed');
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
      @submit="$emit('filter:changed')"
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
