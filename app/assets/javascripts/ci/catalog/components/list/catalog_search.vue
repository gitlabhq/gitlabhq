<script>
import { GlSearchBoxByClick, GlSorting } from '@gitlab/ui';
import { __ } from '~/locale';
import { SORT_ASC, SORT_DESC, SORT_OPTION_CREATED, SORT_OPTION_RELEASED } from '../../constants';

export default {
  components: {
    GlSearchBoxByClick,
    GlSorting,
  },
  data() {
    return {
      currentSortOption: SORT_OPTION_RELEASED,
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
        (sort) => sort.value === this.currentSortOption,
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
      this.currentSortOption = sortingItem;
    },
  },
  sortOptions: [
    { value: SORT_OPTION_RELEASED, text: __('Released at') },
    { value: SORT_OPTION_CREATED, text: __('Created at') },
  ],
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
      :sort-options="$options.sortOptions"
      :sort-by="currentSortOption"
      data-testid="catalog-sorting-option-button"
      @sortByChange="setSelectedSortOption"
      @sortDirectionChange="onSortDirectionChange"
    />
  </div>
</template>
