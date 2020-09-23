<script>
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
    initialFilter: {
      type: String,
      required: false,
      default: null,
    },
    filters: {
      type: Object,
      required: true,
    },
    filtersArray: {
      type: Array,
      required: true,
    },
    header: {
      type: String,
      required: true,
    },
    param: {
      type: String,
      required: true,
    },
    scope: {
      type: String,
      required: true,
    },
    supportedScopes: {
      type: Array,
      required: true,
    },
  },
  computed: {
    filter() {
      return this.initialFilter || this.filters.ANY.value;
    },
    selectedFilterText() {
      const f = this.filtersArray.find(({ value }) => value === this.selectedFilter);
      if (!f || f === this.filters.ANY) {
        return sprintf(s__('Any %{header}'), { header: this.header });
      }

      return f.label;
    },
    showDropdown() {
      return this.supportedScopes.includes(this.scope);
    },
    selectedFilter: {
      get() {
        if (this.filtersArray.some(({ value }) => value === this.filter)) {
          return this.filter;
        }

        return this.filters.ANY.value;
      },
      set(filter) {
        visitUrl(setUrlParams({ [this.param]: filter }));
      },
    },
  },
  methods: {
    dropDownItemClass(filter) {
      return {
        'gl-border-b-solid gl-border-b-gray-100 gl-border-b-1 gl-pb-2! gl-mb-2':
          filter === this.filters.ANY,
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
      {{ header }}
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
