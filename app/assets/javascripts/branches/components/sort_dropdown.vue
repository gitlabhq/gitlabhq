<script>
import { GlCollapsibleListbox, GlSearchBoxByClick } from '@gitlab/ui';
import { mergeUrlParams, visitUrl, getParameterValues } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';

export default {
  i18n: {
    searchPlaceholder: s__('Branches|Filter by branch name'),
  },
  components: {
    GlCollapsibleListbox,
    GlSearchBoxByClick,
  },
  // external parameters
  inject: [
    'projectBranchesFilteredPath',
    'sortOptions', // dropdown choices (value, text) pairs
    'showDropdown', // if not set, only text filter is shown
    'sortedBy', // (required) value of choice to sort by
  ],
  // own attributes, also in created()
  data() {
    return {
      searchTerm: getParameterValues('search')[0] || '',
    };
  },
  computed: {
    selectedSortMethodName() {
      return this.sortOptions[this.selectedKey];
    },
    listboxItems() {
      return Object.entries(this.sortOptions).map(([value, text]) => ({ value, text }));
    },
  },
  // contructor or initialization function
  created() {
    this.selectedKey = this.sortedBy;
  },
  methods: {
    visitUrlFromOption(sortKey) {
      this.selectedKey = sortKey;
      const urlParams = {};

      urlParams.sort = sortKey;

      urlParams.search = this.searchTerm.length > 0 ? this.searchTerm : null;

      if (urlParams.search) {
        urlParams.state = 'all';
      }

      const newUrl = mergeUrlParams(urlParams, this.projectBranchesFilteredPath);
      visitUrl(newUrl);
    },
  },
};
</script>
<template>
  <div class="gl-flex gl-grow">
    <gl-search-box-by-click
      v-model="searchTerm"
      :placeholder="$options.i18n.searchPlaceholder"
      class="gl-mr-3"
      data-testid="branch-search"
      @submit="visitUrlFromOption(selectedKey)"
    />

    <gl-collapsible-listbox
      v-if="showDropdown"
      v-model="selectedKey"
      :items="listboxItems"
      :toggle-text="selectedSortMethodName"
      class="gl-mr-3"
      data-testid="branches-dropdown"
      @select="visitUrlFromOption(selectedKey)"
    />
  </div>
</template>
