<script>
import { GlSearchBoxByClick, GlSorting, GlSortingItem } from '@gitlab/ui';
import { __ } from '~/locale';
import { SORT_ASC, SORT_DESC, SORT_OPTION_CREATED } from '../../constants';

export default {
  components: {
    GlSearchBoxByClick,
    GlSorting,
    GlSortingItem,
  },
  data() {
    return {
      currentSortOption: SORT_OPTION_CREATED,
      isAscending: false,
      searchTerm: '',
    };
  },
  computed: {
    currentSortDirection() {
      return this.isAscending ? SORT_ASC : SORT_DESC;
    },
    currentSorting() {
      return `${this.currentSortOption}_${this.currentSortDirection}`;
    },
    currentSortText() {
      const currentSort = this.$options.sortOptions.find(
        (sort) => sort.key === this.currentSortOption,
      );
      return currentSort.text;
    },
  },
  watch: {
    currentSorting(newSorting) {
      this.$emit('update-sorting', newSorting);
    },
  },
  methods: {
    isActiveSort(sortItem) {
      return sortItem === this.currentSortOption;
    },
    onClear() {
      this.$emit('update-search-term', '');
    },
    onSortDirectionChange() {
      this.isAscending = !this.isAscending;
    },
    onSubmitSearch() {
      this.$emit('update-search-term', this.searchTerm);
    },
    setSelectedSortOption(sortingItem) {
      this.currentSortOption = sortingItem.key;
    },
  },
  sortOptions: [{ key: SORT_OPTION_CREATED, text: __('Created at') }],
};
</script>
<template>
  <div class="gl-display-flex gl-gap-3">
    <gl-search-box-by-click
      v-model="searchTerm"
      data-testid="catalog-search-bar"
      @submit="onSubmitSearch"
      @clear="onClear"
    />
    <gl-sorting
      :is-ascending="isAscending"
      :text="currentSortText"
      @sortDirectionChange="onSortDirectionChange"
    >
      <gl-sorting-item
        v-for="sortingItem in $options.sortOptions"
        :key="sortingItem.key"
        :active="isActiveSort(sortingItem.key)"
        @click="setSelectedSortOption(sortingItem)"
      >
        {{ sortingItem.text }}
      </gl-sorting-item>
    </gl-sorting>
  </div>
</template>
