<script>
import { GlDropdown, GlDropdownItem, GlDropdownDivider } from '@gitlab/ui';
import { FILTER_STATES, FILTER_HEADER, FILTER_TEXT } from '../constants';
import { setUrlParams, visitUrl } from '~/lib/utils/url_utility';

const FILTERS_ARRAY = Object.values(FILTER_STATES);

export default {
  name: 'StateFilter',
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
  },
  props: {
    scope: {
      type: String,
      required: true,
    },
    state: {
      type: String,
      required: false,
      default: FILTER_STATES.ANY.value,
      validator: v => FILTERS_ARRAY.some(({ value }) => value === v),
    },
  },
  computed: {
    selectedFilterText() {
      let filterText = FILTER_TEXT;
      if (this.selectedFilter === FILTER_STATES.CLOSED.value) {
        filterText = FILTER_STATES.CLOSED.label;
      } else if (this.selectedFilter === FILTER_STATES.OPEN.value) {
        filterText = FILTER_STATES.OPEN.label;
      }
      return filterText;
    },
    selectedFilter: {
      get() {
        if (FILTERS_ARRAY.some(({ value }) => value === this.state)) {
          return this.state;
        }

        return FILTER_STATES.ANY.value;
      },
      set(state) {
        visitUrl(setUrlParams({ state }));
      },
    },
  },
  methods: {
    dropDownItemClass(filter) {
      return {
        'gl-border-b-solid gl-border-b-gray-100 gl-border-b-1 gl-pb-2! gl-mb-2':
          filter === FILTER_STATES.ANY,
      };
    },
    isFilterSelected(filter) {
      return filter === this.selectedFilter;
    },
    handleFilterChange(state) {
      this.selectedFilter = state;
    },
  },
  filterStates: FILTER_STATES,
  filterHeader: FILTER_HEADER,
  filtersArray: FILTERS_ARRAY,
};
</script>

<template>
  <gl-dropdown
    v-if="scope === 'issues'"
    :text="selectedFilterText"
    class="col-sm-3 gl-pt-4 gl-pl-0"
  >
    <header class="gl-text-center gl-font-weight-bold gl-font-lg">
      {{ $options.filterHeader }}
    </header>
    <gl-dropdown-divider />
    <gl-dropdown-item
      v-for="filter in $options.filtersArray"
      :key="filter.value"
      :is-check-item="true"
      :is-checked="isFilterSelected(filter.value)"
      :class="dropDownItemClass(filter)"
      @click="handleFilterChange(filter.value)"
    >
      {{ filter.label }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
