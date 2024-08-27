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
      type: [Object, Array],
      required: false,
      default: () => {},
    },
    searchTerm: {
      type: String,
      required: false,
      default: '',
    },
    allowMultiselect: {
      type: Boolean,
      required: false,
      default: false,
    },
    customIsSelectedOption: {
      type: Function,
      required: false,
      default: undefined,
    },
    noOptionsText: {
      type: String,
      required: false,
      default: __('No options found'),
    },
  },
  computed: {
    isSearchEmpty() {
      return this.searchTerm === '' && !this.isLoading;
    },
    noOptionsFound() {
      return !this.isSearchEmpty && this.options.length === 0;
    },
    noOptions() {
      return this.isSearchEmpty && this.options.length === 0;
    },
  },
  methods: {
    selectOption(option) {
      this.$emit('set-option', option || null);
      if (!this.allowMultiselect) {
        this.$refs.dropdown.hide();
      }
    },
    isSelected(option) {
      if (this.customIsSelectedOption !== undefined) {
        return this.customIsSelectedOption(option);
      }
      if (Array.isArray(this.selected)) {
        return this.selected.some((label) => label.title === option.title);
      }
      return this.selected && option.id && this.selected.id === option.id;
    },
    showDropdown() {
      this.$refs.dropdown.show();
    },
    setFocus() {
      this.$refs.search?.focusInput();
    },
    setSearchTerm(search) {
      this.$emit('set-search', search);
    },
    avatarUrl(option) {
      return option.avatar_url || option.avatarUrl || null;
    },
    secondaryText(option) {
      // TODO: this has some knowledge of the context where the component is used. We could later rework it.
      return option.username || null;
    },
    optionKey(option) {
      return option.key ? option.key : option.id;
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
    menu-class="!gl-w-full"
    class="gl-w-full"
    v-on="$listeners"
    @shown="setFocus"
  >
    <template #header>
      <slot name="header">
        <gl-search-box-by-type
          ref="search"
          :value="searchTerm"
          :placeholder="searchText"
          @input="setSearchTerm"
        />
      </slot>
    </template>
    <slot name="default">
      <gl-dropdown-form class="gl-relative gl-min-h-7" data-testid="labels-dropdown-content">
        <gl-loading-icon
          v-if="isLoading"
          size="lg"
          class="gl-absolute gl-left-0 gl-right-0 gl-top-0"
        />
        <template v-else>
          <template v-if="isSearchEmpty && presetOptions.length > 0">
            <gl-dropdown-item
              v-for="option in presetOptions"
              :key="option.id"
              :is-checked="isSelected(option)"
              is-check-centered
              is-check-item
              @click.capture.native.stop="selectOption(option)"
            >
              <slot name="preset-item" :item="option">
                {{ option.title }}
              </slot>
            </gl-dropdown-item>
            <gl-dropdown-divider />
          </template>
          <gl-dropdown-item
            v-for="option in options"
            :key="optionKey(option)"
            :is-checked="isSelected(option)"
            is-check-centered
            is-check-item
            :avatar-url="avatarUrl(option)"
            :secondary-text="secondaryText(option)"
            data-testid="unselected-option"
            @click.capture.native.stop="selectOption(option)"
          >
            <slot name="item" :item="option">
              {{ option.title }}
            </slot>
          </gl-dropdown-item>
          <slot v-bind="{ isSelected }" name="grouped-options"></slot>
          <gl-dropdown-item v-if="noOptionsFound" class="!gl-pl-6">
            {{ $options.i18n.noMatchingResults }}
          </gl-dropdown-item>
          <gl-dropdown-item v-if="noOptions">
            {{ noOptionsText }}
          </gl-dropdown-item>
        </template>
      </gl-dropdown-form>
    </slot>
    <template #footer>
      <slot name="footer"></slot>
    </template>
  </gl-dropdown>
</template>
