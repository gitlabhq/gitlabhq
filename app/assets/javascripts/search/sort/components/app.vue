<script>
import {
  GlButtonGroup,
  GlButton,
  GlDropdown,
  GlDropdownItem,
  GlTooltipDirective,
} from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { SORT_DIRECTION_UI } from '../constants';

export default {
  name: 'GlobalSearchSort',
  components: {
    GlButtonGroup,
    GlButton,
    GlDropdown,
    GlDropdownItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    searchSortOptions: {
      type: Array,
      required: true,
    },
  },
  computed: {
    ...mapState(['query']),
    selectedSortOption: {
      get() {
        const { sort } = this.query;

        if (!sort) {
          return this.searchSortOptions[0];
        }

        const sortOption = this.searchSortOptions.find((option) => {
          if (!option.sortable) {
            return option.sortParam === sort;
          }

          return Object.values(option.sortParam).indexOf(sort) !== -1;
        });

        // Handle invalid sort param
        return sortOption || this.searchSortOptions[0];
      },
      set(value) {
        this.setQuery({ key: 'sort', value });
        this.applyQuery();
      },
    },
    sortDirectionData() {
      if (!this.selectedSortOption.sortable) {
        return SORT_DIRECTION_UI.disabled;
      }

      return this.query?.sort?.includes('asc') ? SORT_DIRECTION_UI.asc : SORT_DIRECTION_UI.desc;
    },
  },
  methods: {
    ...mapActions(['applyQuery', 'setQuery']),
    handleSortChange(option) {
      if (!option.sortable) {
        this.selectedSortOption = option.sortParam;
      } else {
        // Default new sort options to desc
        this.selectedSortOption = option.sortParam.desc;
      }
    },
    handleSortDirectionChange() {
      this.selectedSortOption =
        this.sortDirectionData.direction === 'desc'
          ? this.selectedSortOption.sortParam.asc
          : this.selectedSortOption.sortParam.desc;
    },
  },
};
</script>

<template>
  <gl-button-group>
    <gl-dropdown :text="selectedSortOption.title" :right="true" class="w-100">
      <gl-dropdown-item
        v-for="sortOption in searchSortOptions"
        :key="sortOption.title"
        is-check-item
        :is-checked="sortOption.title === selectedSortOption.title"
        @click="handleSortChange(sortOption)"
        >{{ sortOption.title }}</gl-dropdown-item
      >
    </gl-dropdown>
    <gl-button
      v-gl-tooltip
      :disabled="!selectedSortOption.sortable"
      :title="sortDirectionData.tooltip"
      :aria-label="sortDirectionData.tooltip"
      :icon="sortDirectionData.icon"
      @click="handleSortDirectionChange"
    />
  </gl-button-group>
</template>
