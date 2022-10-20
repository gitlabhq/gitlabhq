<script>
import { GlSorting, GlSortingItem } from '@gitlab/ui';
import { mapState } from 'vuex';
import { visitUrl } from '~/lib/utils/url_utility';
import { FIELDS } from '~/members/constants';
import { parseSortParam, buildSortHref } from '~/members/utils';
import { SORT_DIRECTION_UI } from '~/search/sort/constants';

export default {
  name: 'SortDropdown',
  components: { GlSorting, GlSortingItem },
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
        key: field.key,
        label: field.label,
        href: buildSortHref({
          sortBy: field.key,
          sortDesc: false,
          filteredSearchBarTokens: this.filteredSearchBar.tokens,
          filteredSearchBarSearchParam: this.filteredSearchBar.searchParam,
        }),
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
  },
};
</script>

<template>
  <gl-sorting
    class="gl-display-flex"
    dropdown-class="gl-w-full"
    data-testid="members-sort-dropdown"
    :text="activeOptionLabel"
    :is-ascending="isAscending"
    :sort-direction-tool-tip="sortDirectionData.tooltip"
    @sortDirectionChange="handleSortDirectionChange"
  >
    <gl-sorting-item
      v-for="option in filteredOptions"
      :key="option.key"
      :href="option.href"
      :active="isActive(option.key)"
    >
      {{ option.label }}
    </gl-sorting-item>
  </gl-sorting>
</template>
