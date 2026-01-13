<script>
import { GlSorting, GlSearchBoxByClick } from '@gitlab/ui';
import { mergeUrlParams, visitUrl, queryToObject } from '~/lib/utils/url_utility';
import { s__, __ } from '~/locale';
import {
  SORT_DIRECTION_ASC,
  SORT_DIRECTION_DESC,
  SORT_OPTION_NAME,
  SORT_OPTION_UPDATED,
  SORT_OPTION_VERSION,
} from '../constants';

export default {
  i18n: {
    searchPlaceholder: s__('TagsPage|Filter by tag name'),
  },
  components: {
    GlSorting,
    GlSearchBoxByClick,
  },
  inject: ['filterTagsPath'],

  data() {
    const { sort, search } = queryToObject(window.location.search);
    const [key, direction] = sort?.toLowerCase().split(/_(asc|desc)$/) || [];
    const isValidSort = this.$options.sortOptions.some(({ value }) => value === key);

    return {
      sortKey: isValidSort ? key : SORT_OPTION_UPDATED,
      isAscending: direction === SORT_DIRECTION_ASC,
      searchTerm: search || '',
    };
  },

  computed: {
    sortDirection() {
      return this.isAscending ? SORT_DIRECTION_ASC : SORT_DIRECTION_DESC;
    },
    sortText() {
      return this.$options.sortOptions.find(({ value }) => value === this.sortKey)?.text;
    },
  },

  methods: {
    onSortDirectionChange() {
      this.isAscending = !this.isAscending;
      this.visitUrlFromOption();
    },
    setSelectedSortOption(key) {
      this.sortKey = key;
      this.visitUrlFromOption();
    },
    visitUrlFromOption() {
      const urlParams = {
        sort: `${this.sortKey}_${this.sortDirection}`,
        search: this.searchTerm || null,
      };
      const newUrl = mergeUrlParams(urlParams, this.filterTagsPath);
      visitUrl(newUrl);
    },
  },
  sortOptions: [
    { value: SORT_OPTION_NAME, text: __('Name') },
    { value: SORT_OPTION_UPDATED, text: __('Updated date') },
    { value: SORT_OPTION_VERSION, text: __('Version') },
  ],
};
</script>
<template>
  <div class="gl-flex gl-flex-col gl-gap-3 @md/panel:gl-flex-row">
    <gl-search-box-by-click
      v-model="searchTerm"
      :placeholder="$options.i18n.searchPlaceholder"
      @submit="visitUrlFromOption"
    />
    <gl-sorting
      dropdown-class="gl-w-full !gl-flex"
      block
      :text="sortText"
      :sort-options="$options.sortOptions"
      :sort-by="sortKey"
      :is-ascending="isAscending"
      @sort-by-change="setSelectedSortOption"
      @sort-direction-change="onSortDirectionChange"
    />
  </div>
</template>
