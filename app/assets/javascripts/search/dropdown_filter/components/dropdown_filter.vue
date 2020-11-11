<script>
import { mapState } from 'vuex';
import { GlDropdown, GlDropdownItem, GlDropdownDivider } from '@gitlab/ui';
import { setUrlParams, visitUrl } from '~/lib/utils/url_utility';
import { sprintf, s__ } from '~/locale';

export default {
  name: 'DropdownFilter',
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
  },
  props: {
    filterData: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState(['query']),
    scope() {
      return this.query.scope;
    },
    supportedScopes() {
      return Object.values(this.filterData.scopes);
    },
    initialFilter() {
      return this.query[this.filterData.filterParam];
    },
    filter() {
      return this.initialFilter || this.filterData.filters.ANY.value;
    },
    filtersArray() {
      return this.filterData.filterByScope[this.scope];
    },
    selectedFilter: {
      get() {
        if (this.filtersArray.some(({ value }) => value === this.filter)) {
          return this.filter;
        }

        return this.filterData.filters.ANY.value;
      },
      set(filter) {
        // we need to remove the pagination cursor to ensure the
        // relevancy of the new results

        visitUrl(
          setUrlParams({
            page: null,
            [this.filterData.filterParam]: filter,
          }),
        );
      },
    },
    selectedFilterText() {
      const f = this.filtersArray.find(({ value }) => value === this.selectedFilter);
      if (!f || f === this.filterData.filters.ANY) {
        return sprintf(s__('Any %{header}'), { header: this.filterData.header });
      }

      return f.label;
    },
    showDropdown() {
      return this.supportedScopes.includes(this.scope);
    },
  },
  methods: {
    dropDownItemClass(filter) {
      return {
        'gl-border-b-solid gl-border-b-gray-100 gl-border-b-1 gl-pb-2! gl-mb-2':
          filter === this.filterData.filters.ANY,
      };
    },
    isFilterSelected(filter) {
      return filter === this.selectedFilter;
    },
    handleFilterChange(filter) {
      this.selectedFilter = filter;
    },
  },
};
</script>

<template>
  <gl-dropdown
    v-if="showDropdown"
    :text="selectedFilterText"
    class="col-3 gl-pt-4 gl-pl-0 gl-pr-0 gl-mr-4"
    menu-class="gl-w-full! gl-pl-0"
  >
    <header class="gl-text-center gl-font-weight-bold gl-font-lg">
      {{ filterData.header }}
    </header>
    <gl-dropdown-divider />
    <gl-dropdown-item
      v-for="f in filtersArray"
      :key="f.value"
      :is-check-item="true"
      :is-checked="isFilterSelected(f.value)"
      :class="dropDownItemClass(f)"
      @click="handleFilterChange(f.value)"
    >
      {{ f.label }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
