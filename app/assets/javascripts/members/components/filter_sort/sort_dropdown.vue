<script>
import { mapState } from 'vuex';
import { GlDropdown, GlDropdownItem, GlFormGroup } from '@gitlab/ui';
import { parseSortParam, buildSortUrl } from '~/members/utils';
import { FIELDS } from '~/members/constants';

export default {
  name: 'SortDropdown',
  components: { GlDropdown, GlDropdownItem, GlFormGroup },
  computed: {
    ...mapState(['tableSortableFields', 'filteredSearchBar']),
    sort() {
      return parseSortParam(this.tableSortableFields);
    },
    filteredOptions() {
      const buildOption = (field, sortDesc) => ({
        ...(sortDesc ? field.sort.desc : field.sort.asc),
        key: field.key,
        sortDesc,
        url: buildSortUrl({
          sortBy: field.key,
          sortDesc,
          filteredSearchBarTokens: this.filteredSearchBar.tokens,
          filteredSearchBarSearchParam: this.filteredSearchBar.searchParam,
        }),
      });

      return FIELDS.filter(
        field => this.tableSortableFields.includes(field.key) && field.sort,
      ).flatMap(field => [buildOption(field, false), buildOption(field, true)]);
    },
  },
  methods: {
    isChecked(key, sortDesc) {
      return this.sort?.sortBy === key && this.sort?.sortDesc === sortDesc;
    },
  },
};
</script>

<template>
  <gl-form-group
    :label="__('Sort by')"
    class="gl-mb-0"
    label-cols="auto"
    label-class="gl-align-self-center gl-pb-0!"
  >
    <gl-dropdown
      :text="sort.sortByLabel"
      block
      toggle-class="gl-mb-0"
      data-testid="members-sort-dropdown"
      right
    >
      <gl-dropdown-item
        v-for="option in filteredOptions"
        :key="option.param"
        :href="option.url"
        is-check-item
        :is-checked="isChecked(option.key, option.sortDesc)"
      >
        {{ option.label }}
      </gl-dropdown-item>
    </gl-dropdown>
  </gl-form-group>
</template>
