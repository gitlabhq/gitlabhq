<script>
import { GlButton, GlSearchBoxByType } from '@gitlab/ui';

export default {
  components: {
    GlButton,
    GlSearchBoxByType,
  },
  props: {
    labelsCreateTitle: {
      type: String,
      required: true,
    },
    labelsListTitle: {
      type: String,
      required: true,
    },
    showDropdownContentsCreateView: {
      type: Boolean,
      required: true,
    },
    labelsFetchInProgress: {
      type: Boolean,
      required: false,
      default: false,
    },
    searchKey: {
      type: String,
      required: true,
    },
    isStandalone: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    dropdownTitle() {
      return this.showDropdownContentsCreateView ? this.labelsCreateTitle : this.labelsListTitle;
    },
  },
  methods: {
    focusInput() {
      this.$refs.searchInput?.focusInput();
    },
  },
};
</script>

<template>
  <div data-testid="dropdown-header">
    <div
      v-if="!isStandalone"
      class="dropdown-title gl-mb-0 gl-flex gl-items-center gl-pb-4 gl-pt-2"
      data-testid="dropdown-header-title"
    >
      <gl-button
        v-if="showDropdownContentsCreateView"
        :aria-label="__('Go back')"
        variant="link"
        size="small"
        class="js-btn-back dropdown-header-button !gl-p-0"
        icon="arrow-left"
        data-testid="go-back-button"
        @click.stop="$emit('toggleDropdownContentsCreateView')"
      />
      <span class="gl-grow">{{ dropdownTitle }}</span>
      <gl-button
        :aria-label="__('Close')"
        variant="link"
        size="small"
        class="dropdown-header-button !gl-p-0"
        icon="close"
        data-testid="close-labels-dropdown-button"
        @click="$emit('closeDropdown')"
      />
    </div>
    <gl-search-box-by-type
      v-if="!showDropdownContentsCreateView"
      ref="searchInput"
      :value="searchKey"
      :placeholder="__('Search labels')"
      :disabled="labelsFetchInProgress"
      data-testid="dropdown-input-field"
      @input="$emit('input', $event)"
      @keydown.enter="$emit('searchEnter', $event)"
    />
  </div>
</template>
