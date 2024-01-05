<script>
import { GlButton, GlForm, GlLoadingIcon, GlCollapsibleListbox } from '@gitlab/ui';
import { isEmpty } from 'lodash';

import { s__, __ } from '~/locale';

export default {
  i18n: {
    none: s__('WorkItem|None'),
    noMatchingResults: s__('WorkItem|No matching results'),
    editButtonLabel: __('Edit'),
    applyButtonLabel: __('Apply'),
    resetButtonText: __('Clear'),
  },
  components: {
    GlButton,
    GlLoadingIcon,
    GlForm,
    GlCollapsibleListbox,
  },
  props: {
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    dropdownLabel: {
      type: String,
      required: true,
    },
    dropdownName: {
      type: String,
      required: true,
    },
    listItems: {
      type: Array,
      required: false,
      default: () => [],
    },
    itemValue: {
      type: Object,
      required: false,
      default: null,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    updateInProgress: {
      type: Boolean,
      required: false,
      default: false,
    },
    resetButtonLabel: {
      type: String,
      required: false,
      default: '',
    },
    headerText: {
      type: String,
      required: false,
      default: '',
    },
    toggleDropdownText: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isEditing: false,
      localSelectedItem: this.itemValue?.id,
    };
  },
  computed: {
    hasValue() {
      return this.itemValue != null || !isEmpty(this.item);
    },
    listboxText() {
      return (
        this.listItems.find(({ value }) => this.localSelectedItem === value)?.text ||
        this.itemValue?.title ||
        this.$options.i18n.none
      );
    },
    inputId() {
      return `work-item-dropdown-listbox-value-${this.dropdownName}`;
    },
    toggleText() {
      return this.toggleDropdownText || this.listboxText;
    },
    resetButton() {
      return this.resetButtonLabel || this.$options.i18n.resetButtonText;
    },
  },
  watch: {
    itemValue: {
      handler(newVal) {
        if (!this.isEditing) {
          this.localSelectedItem = newVal?.id;
        }
      },
    },
  },
  methods: {
    setSearchKey(value) {
      this.$emit('searchStarted', value);
    },
    handleItemClick(item) {
      this.localSelectedItem = item;
      this.$emit('updateValue', item);
    },
    onListboxShown() {
      this.$emit('dropdownShown');
    },
    onListboxHide() {
      this.isEditing = false;
    },
    unassignValue() {
      this.localSelectedItem = null;
      this.isEditing = false;
      this.$emit('updateValue', null);
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-display-flex gl-align-items-center gl-gap-3">
      <!-- hide header when editing, since we then have a form label. Keep it reachable for screenreader nav  -->
      <h3 :class="{ 'gl-sr-only': isEditing }" class="gl-mb-0! gl-heading-scale-5">
        {{ dropdownLabel }}
      </h3>
      <gl-loading-icon v-if="updateInProgress" />
      <gl-button
        v-if="canUpdate && !isEditing"
        data-testid="edit-button"
        category="tertiary"
        size="small"
        class="gl-ml-auto gl-mr-2"
        :disabled="updateInProgress"
        @click="isEditing = true"
        >{{ $options.i18n.editButtonLabel }}</gl-button
      >
    </div>
    <gl-form v-if="isEditing">
      <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center">
        <label :for="inputId" class="gl-mb-0">{{ dropdownLabel }}</label>
        <gl-button
          data-testid="apply-button"
          category="tertiary"
          size="small"
          class="gl-mr-2"
          :disabled="updateInProgress"
          @click="isEditing = false"
          >{{ $options.i18n.applyButtonLabel }}</gl-button
        >
      </div>
      <gl-collapsible-listbox
        :id="inputId"
        block
        searchable
        start-opened
        is-check-centered
        fluid-width
        :searching="loading"
        :header-text="headerText"
        :toggle-text="toggleText"
        :no-results-text="$options.i18n.noMatchingResults"
        :items="listItems"
        :selected="localSelectedItem"
        :reset-button-label="resetButton"
        @reset="unassignValue"
        @search="setSearchKey"
        @select="handleItemClick"
        @shown="onListboxShown"
        @hidden="onListboxHide"
      >
        <template #list-item="{ item }">
          <slot name="list-item" :item="item">{{ item.text }}</slot>
        </template>
      </gl-collapsible-listbox>
    </gl-form>
    <slot v-else-if="hasValue" name="readonly">
      {{ listboxText }}
    </slot>
    <div v-else class="gl-text-secondary">
      {{ $options.i18n.none }}
    </div>
  </div>
</template>
