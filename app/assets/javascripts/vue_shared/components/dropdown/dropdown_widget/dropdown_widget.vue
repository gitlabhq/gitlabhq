<script>
import {
  GlIcon,
  GlLoadingIcon,
  GlDropdown,
  GlDropdownForm,
  GlDropdownDivider,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { __ } from '~/locale';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';

export default {
  components: {
    GlIcon,
    GlLoadingIcon,
    GlDropdown,
    GlDropdownForm,
    GlDropdownDivider,
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlSearchBoxByType,
    TooltipOnTruncate,
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
    groupedOptions: {
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
      if (!this.allowMultiselect) {
        this.$refs.dropdown.hide();
      }
    },
    isSelected(option) {
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
    menu-class="gl-w-full!"
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
          class="js-dropdown-input-field"
          @input="setSearchTerm"
        />
      </slot>
    </template>
    <slot name="default">
      <gl-dropdown-form class="gl-relative gl-min-h-7" data-qa-selector="labels_dropdown_content">
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
              @click.native.capture.stop="selectOption(option)"
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
            @click.native.capture.stop="selectOption(option)"
          >
            <slot name="item" :item="option">
              {{ option.title }}
            </slot>
          </gl-dropdown-item>
          <template v-for="(optionGroup, index) in groupedOptions">
            <gl-dropdown-divider v-if="index !== 0" :key="index" />
            <gl-dropdown-section-header :key="optionGroup.id">
              <div class="gl-display-flex gl-max-w-full">
                <tooltip-on-truncate
                  :title="optionGroup.title"
                  class="gl-text-truncate gl-flex-grow-1"
                >
                  {{ optionGroup.title }}
                </tooltip-on-truncate>
                <span v-if="optionGroup.secondaryText" class="gl-float-right gl-font-weight-normal">
                  <gl-icon name="clock" class="gl-mr-2" />
                  {{ optionGroup.secondaryText }}
                </span>
              </div>
            </gl-dropdown-section-header>
            <gl-dropdown-item
              v-for="option in optionGroup.options"
              :key="optionKey(option)"
              :is-checked="isSelected(option)"
              is-check-centered
              is-check-item
              data-testid="unselected-option"
              @click="selectOption(option)"
            >
              <slot name="item" :item="option">
                {{ option.title }}
              </slot>
            </gl-dropdown-item>
          </template>
          <gl-dropdown-item v-if="noOptionsFound" class="gl-pl-6!">
            {{ $options.i18n.noMatchingResults }}
          </gl-dropdown-item>
        </template>
      </gl-dropdown-form>
    </slot>
    <template #footer>
      <slot name="footer"></slot>
    </template>
  </gl-dropdown>
</template>
