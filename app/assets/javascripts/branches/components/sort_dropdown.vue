<script>
import { GlCollapsibleListbox, GlSearchBoxByClick } from '@gitlab/ui';
import { mergeUrlParams, visitUrl, getParameterValues } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';

const OVERVIEW_MODE = 'overview';

export default {
  i18n: {
    searchPlaceholder: s__('Branches|Filter by branch name'),
  },
  components: {
    GlCollapsibleListbox,
    GlSearchBoxByClick,
  },
  inject: ['projectBranchesFilteredPath', 'sortOptions', 'mode'],
  data() {
    return {
      selectedKey: 'updated_desc',
      searchTerm: '',
    };
  },
  computed: {
    shouldShowDropdown() {
      return this.mode !== OVERVIEW_MODE;
    },
    selectedSortMethodName() {
      return this.sortOptions[this.selectedKey];
    },
    listboxItems() {
      return Object.entries(this.sortOptions).map(([value, text]) => ({ value, text }));
    },
  },
  created() {
    const sortValue = getParameterValues('sort');
    const searchValue = getParameterValues('search');

    if (sortValue.length > 0) {
      [this.selectedKey] = sortValue;
    }

    if (searchValue.length > 0) {
      [this.searchTerm] = searchValue;
    }
  },
  methods: {
    visitUrlFromOption(sortKey) {
      this.selectedKey = sortKey;
      const urlParams = {};

      if (this.mode !== OVERVIEW_MODE) {
        urlParams.sort = sortKey;
      }

      urlParams.search = this.searchTerm.length > 0 ? this.searchTerm : null;

      const newUrl = mergeUrlParams(urlParams, this.projectBranchesFilteredPath);
      visitUrl(newUrl);
    },
  },
};
</script>
<template>
  <div class="gl-display-flex">
    <gl-search-box-by-click
      v-model="searchTerm"
      :placeholder="$options.i18n.searchPlaceholder"
      class="gl-mr-3"
      data-testid="branch-search"
      @submit="visitUrlFromOption(selectedKey)"
    />

    <gl-collapsible-listbox
      v-if="shouldShowDropdown"
      v-model="selectedKey"
      :items="listboxItems"
      :toggle-text="selectedSortMethodName"
      class="gl-mr-3"
      data-testid="branches-dropdown"
      @select="visitUrlFromOption(selectedKey)"
    />
  </div>
</template>
