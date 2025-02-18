<script>
import { GlSearchBoxByClick, GlSorting } from '@gitlab/ui';
import { __ } from '~/locale';
import {
  SORT_ASC,
  SORT_DESC,
  SORT_OPTION_CREATED,
  SORT_OPTION_RELEASED,
  SORT_OPTION_STAR_COUNT,
  SORT_OPTION_POPULARITY,
} from '../../constants';

export default {
  components: {
    GlSearchBoxByClick,
    GlSorting,
  },
  props: {
    initialSearchTerm: {
      default: '',
      required: false,
      type: String,
    },
  },
  data() {
    return {
      currentSortOption: SORT_OPTION_POPULARITY,
      isAscending: false,
      searchTerm: this.initialSearchTerm,
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
    { value: SORT_OPTION_POPULARITY, text: __('Popularity') },
    { value: SORT_OPTION_RELEASED, text: __('Released date') },
    { value: SORT_OPTION_CREATED, text: __('Created date') },
    { value: SORT_OPTION_STAR_COUNT, text: __('Star count') },
  ],
};
</script>
<template>
  <div class="gl-border-b gl-flex gl-gap-3 gl-bg-subtle gl-p-5">
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
