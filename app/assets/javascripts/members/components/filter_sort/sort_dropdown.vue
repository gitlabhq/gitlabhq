<script>
import { GlSorting } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { visitUrl } from '~/lib/utils/url_utility';
import { FIELDS } from '~/members/constants';
import { parseSortParam, buildSortHref } from '~/members/utils';
import { SORT_DIRECTION_UI } from '~/search/sort/constants';

export default {
  name: 'SortDropdown',
  components: { GlSorting },
  inject: ['namespace'],
  computed: {
    ...mapState({
      tableSortableFields(state) {
        return state[this.namespace].tableSortableFields;
      },
      filteredSearchBar(state) {
        return state[this.namespace].filteredSearchBar;
      },
    }),
    sort() {
      return parseSortParam(this.tableSortableFields);
    },
    activeOption() {
      return FIELDS.find((field) => field.key === this.sort.sortByKey);
    },
    activeOptionLabel() {
      return this.activeOption?.label;
    },
    activeOptionKey() {
      return this.activeOption?.key;
    },
    isAscending() {
      return !this.sort.sortDesc;
    },
    sortDirectionData() {
      return this.isAscending ? SORT_DIRECTION_UI.asc : SORT_DIRECTION_UI.desc;
    },
    filteredOptions() {
      return FIELDS.filter(
        (field) => this.tableSortableFields.includes(field.key) && field.sort,
      ).map((field) => ({
        text: field.label,
        value: field.key,
      }));
    },
  },
  methods: {
    isActive(key) {
      return this.activeOption.key === key;
    },
    handleSortDirectionChange() {
      visitUrl(
        buildSortHref({
          sortBy: this.activeOption.key,
          sortDesc: !this.sort.sortDesc,
          filteredSearchBarTokens: this.filteredSearchBar.tokens,
          filteredSearchBarSearchParam: this.filteredSearchBar.searchParam,
        }),
      );
    },
    handleSortingItemClick(value) {
      visitUrl(
        buildSortHref({
          sortBy: value,
          sortDesc: false,
          filteredSearchBarTokens: this.filteredSearchBar.tokens,
          filteredSearchBarSearchParam: this.filteredSearchBar.searchParam,
        }),
      );
    },
  },
};
</script>

<template>
  <gl-sorting
    class="gl-flex"
    dropdown-class="gl-w-full"
    block
    data-testid="members-sort-dropdown"
    :text="activeOptionLabel"
    :is-ascending="isAscending"
    :sort-direction-tool-tip="sortDirectionData.tooltip"
    :sort-options="filteredOptions"
    :sort-by="activeOptionKey"
    @sortByChange="handleSortingItemClick"
    @sortDirectionChange="handleSortDirectionChange"
  />
</template>
