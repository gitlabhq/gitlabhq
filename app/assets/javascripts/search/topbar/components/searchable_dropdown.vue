<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlSearchBoxByType,
  GlLoadingIcon,
  GlIcon,
  GlButton,
  GlSkeletonLoader,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __ } from '~/locale';
import { ANY_OPTION } from '../constants';
import SearchableDropdownItem from './searchable_dropdown_item.vue';

export default {
  i18n: {
    clearLabel: __('Clear'),
  },
  name: 'SearchableDropdown',
  components: {
    GlDropdown,
    GlDropdownItem,
    GlSearchBoxByType,
    GlLoadingIcon,
    GlIcon,
    GlButton,
    GlSkeletonLoader,
    SearchableDropdownItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    headerText: {
      type: String,
      required: false,
      default: "__('Filter')",
    },
    name: {
      type: String,
      required: false,
      default: 'name',
    },
    fullName: {
      type: String,
      required: false,
      default: 'name',
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    selectedItem: {
      type: Object,
      required: true,
    },
    items: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      searchText: '',
      hasBeenOpened: false,
    };
  },
  methods: {
    isSelected(selected) {
      return selected.id === this.selectedItem.id;
    },
    openDropdown() {
      if (!this.hasBeenOpened) {
        this.hasBeenOpened = true;
        this.$emit('first-open');
      }

      this.$emit('search', this.searchText);
    },
    resetDropdown() {
      this.$emit('change', ANY_OPTION);
    },
    updateDropdown(item) {
      this.$emit('change', item);
    },
  },
  ANY_OPTION,
};
</script>

<template>
  <gl-dropdown
    class="gl-w-full"
    menu-class="global-search-dropdown-menu"
    toggle-class="gl-text-truncate"
    :header-text="headerText"
    :right="true"
    @show="openDropdown"
    @shown="$refs.searchBox.focusInput()"
  >
    <template #button-content>
      <span class="dropdown-toggle-text gl-flex-grow-1 gl-text-truncate">
        {{ selectedItem[name] }}
      </span>
      <gl-loading-icon v-if="loading" size="sm" inline class="gl-mr-3" />
      <gl-button
        v-if="!isSelected($options.ANY_OPTION)"
        v-gl-tooltip
        name="clear"
        category="tertiary"
        :title="$options.i18n.clearLabel"
        :aria-label="$options.i18n.clearLabel"
        class="gl-p-0! gl-mr-2"
        @keydown.enter.stop="resetDropdown"
        @click.stop="resetDropdown"
      >
        <gl-icon name="clear" />
      </gl-button>
      <gl-icon name="chevron-down" />
    </template>
    <div class="gl-sticky gl-top-0 gl-z-index-1 gl-bg-white">
      <gl-search-box-by-type
        ref="searchBox"
        v-model="searchText"
        class="gl-m-3"
        :debounce="500"
        @input="openDropdown"
      />
      <gl-dropdown-item
        class="gl-border-b-solid gl-border-b-gray-100 gl-border-b-1 gl-pb-2! gl-mb-2"
        :is-check-item="true"
        :is-checked="isSelected($options.ANY_OPTION)"
        :is-check-centered="true"
        @click="updateDropdown($options.ANY_OPTION)"
      >
        <span data-testid="item-title">{{ $options.ANY_OPTION.name }}</span>
      </gl-dropdown-item>
    </div>
    <div v-if="!loading">
      <searchable-dropdown-item
        v-for="item in items"
        :key="item.id"
        :item="item"
        :selected-item="selectedItem"
        :search-text="searchText"
        :name="name"
        :full-name="fullName"
        @change="updateDropdown"
      />
    </div>
    <div v-if="loading" class="gl-mx-4 gl-mt-3">
      <gl-skeleton-loader :height="100">
        <rect y="0" width="90%" height="20" rx="4" />
        <rect y="40" width="70%" height="20" rx="4" />
        <rect y="80" width="80%" height="20" rx="4" />
      </gl-skeleton-loader>
    </div>
  </gl-dropdown>
</template>
