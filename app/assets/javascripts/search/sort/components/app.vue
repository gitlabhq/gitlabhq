<script>
import { GlCollapsibleListbox, GlButtonGroup, GlButton, GlTooltipDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import { SORT_DIRECTION_UI } from '../constants';

export default {
  name: 'GlobalSearchSort',
  components: {
    GlCollapsibleListbox,
    GlButtonGroup,
    GlButton,
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
  data() {
    return {
      selectedSortOptionTitle: '',
    };
  },
  computed: {
    ...mapState(['query']),
    listboxOptions() {
      return this.searchSortOptions.map((option) => ({
        text: option.title,
        value: option.title,
      }));
    },
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
  watch: {
    selectedSortOption: {
      handler() {
        this.selectedSortOptionTitle = this.selectedSortOption.title;
      },
      immediate: true,
    },
  },
  methods: {
    ...mapActions(['applyQuery', 'setQuery']),
    handleSortChange(value) {
      const selectedOption = this.searchSortOptions.find((option) => option.title === value);
      if (!selectedOption.sortable) {
        this.selectedSortOption = selectedOption.sortParam;
      } else {
        // Default new sort options to desc
        this.selectedSortOption = selectedOption.sortParam.desc;
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
    <gl-collapsible-listbox
      v-model="selectedSortOptionTitle"
      placement="bottom-end"
      class="gl-z-1"
      toggle-class="!gl-rounded-tr-none !gl-rounded-br-none"
      :toggle-text="selectedSortOptionTitle"
      :items="listboxOptions"
      @select="handleSortChange"
    />
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
