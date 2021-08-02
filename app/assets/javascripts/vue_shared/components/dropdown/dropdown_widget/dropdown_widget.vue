<script>
import {
  GlLoadingIcon,
  GlDropdown,
  GlDropdownForm,
  GlDropdownDivider,
  GlDropdownItem,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlLoadingIcon,
    GlDropdown,
    GlDropdownForm,
    GlDropdownDivider,
    GlDropdownItem,
    GlSearchBoxByType,
  },
  props: {
    selectText: {
      type: String,
      required: false,
      default: __('Select'),
    },
    searchText: {
      type: String,
      required: false,
      default: __('Search'),
    },
    presetOptions: {
      type: Array,
      required: false,
      default: () => [],
    },
    options: {
      type: Array,
      required: false,
      default: () => [],
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    selected: {
      type: Object,
      required: false,
      default: () => {},
    },
    searchTerm: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    isSearchEmpty() {
      return this.searchTerm === '' && !this.isLoading;
    },
    noOptionsFound() {
      return !this.isSearchEmpty && this.options.length === 0;
    },
  },
  methods: {
    selectOption(option) {
      this.$emit('set-option', option || null);
    },
    isSelected(option) {
      return this.selected && this.selected.title === option.title;
    },
    showDropdown() {
      this.$refs.dropdown.show();
    },
    setFocus() {
      this.$refs.search.focusInput();
    },
    setSearchTerm(search) {
      this.$emit('set-search', search);
    },
  },
  i18n: {
    noMatchingResults: __('No matching results'),
  },
};
</script>

<template>
  <gl-dropdown
    ref="dropdown"
    :text="selectText"
    lazy
    menu-class="gl-w-full!"
    class="gl-w-full"
    v-on="$listeners"
    @shown="setFocus"
  >
    <template #header>
      <gl-search-box-by-type
        ref="search"
        :value="searchTerm"
        :placeholder="searchText"
        class="js-dropdown-input-field"
        @input="setSearchTerm"
      />
    </template>
    <gl-dropdown-form class="gl-relative gl-min-h-7">
      <gl-loading-icon
        v-if="isLoading"
        size="md"
        class="gl-absolute gl-left-0 gl-top-0 gl-right-0"
      />
      <template v-else>
        <template v-if="isSearchEmpty && presetOptions.length > 0">
          <gl-dropdown-item
            v-for="option in presetOptions"
            :key="option.id"
            :is-checked="isSelected(option)"
            :is-check-centered="true"
            :is-check-item="true"
            @click="selectOption(option)"
          >
            {{ option.title }}
          </gl-dropdown-item>
          <gl-dropdown-divider />
        </template>
        <gl-dropdown-item
          v-for="option in options"
          :key="option.id"
          :is-checked="isSelected(option)"
          :is-check-centered="true"
          :is-check-item="true"
          data-testid="unselected-option"
          @click="selectOption(option)"
        >
          {{ option.title }}
        </gl-dropdown-item>
        <gl-dropdown-item v-if="noOptionsFound" class="gl-pl-6!">
          {{ $options.i18n.noMatchingResults }}
        </gl-dropdown-item>
      </template>
    </gl-dropdown-form>
    <template #footer>
      <slot name="footer"></slot>
    </template>
  </gl-dropdown>
</template>
