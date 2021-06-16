<script>
import { GlDropdown, GlDropdownItem, GlSearchBoxByClick } from '@gitlab/ui';
import { mergeUrlParams, visitUrl, getParameterValues } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';

const OVERVIEW_MODE = 'overview';

export default {
  i18n: {
    searchPlaceholder: s__('Branches|Filter by branch name'),
  },
  components: {
    GlDropdown,
    GlDropdownItem,
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
    isSortMethodSelected(sortKey) {
      return sortKey === this.selectedKey;
    },
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
    <gl-dropdown
      v-if="shouldShowDropdown"
      :text="selectedSortMethodName"
      class="gl-mr-3"
      data-testid="branches-dropdown"
    >
      <gl-dropdown-item
        v-for="(value, key) in sortOptions"
        :key="key"
        :is-checked="isSortMethodSelected(key)"
        is-check-item
        @click="visitUrlFromOption(key)"
        >{{ value }}</gl-dropdown-item
      >
    </gl-dropdown>
  </div>
</template>
