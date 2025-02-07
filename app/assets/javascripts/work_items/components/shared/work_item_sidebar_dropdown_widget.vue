<script>
import { GlButton, GlForm, GlLoadingIcon, GlCollapsibleListbox } from '@gitlab/ui';
import { isEmpty, debounce } from 'lodash';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

import { s__, __, sprintf } from '~/locale';

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
      type: [Array, String],
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
    multiSelect: {
      type: Boolean,
      required: false,
      default: false,
    },
    showFooter: {
      type: Boolean,
      required: false,
      default: false,
    },
    infiniteScroll: {
      type: Boolean,
      required: false,
      default: false,
    },
    infiniteScrollLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    clearSearchOnItemSelect: {
      type: Boolean,
      required: false,
      default: false,
    },
    searchable: {
      type: Boolean,
      required: false,
      default: true,
    },
    createdLabelId: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  data() {
    return {
      isEditing: false,
      localSelectedItem: this.itemValue,
      isDirty: false,
    };
  },
  computed: {
    hasValue() {
      return this.multiSelect ? !isEmpty(this.itemValue) : this.itemValue !== null;
    },
    inputId() {
      return `work-item-dropdown-listbox-value-${this.dropdownName}`;
    },
    resetButton() {
      return this.resetButtonLabel || this.$options.i18n.resetButtonText;
    },
    toggleText() {
      return !this.toggleDropdownText && !this.hasValue
        ? sprintf(__(`No %{label}`), { label: this.dropdownLabel.toLowerCase() })
        : this.toggleDropdownText;
    },
  },
  watch: {
    itemValue: {
      handler(newVal) {
        if (!this.isEditing) {
          this.localSelectedItem = newVal;
          this.isDirty = false;
        }
      },
    },
    createdLabelId(id) {
      this.localSelectedItem.push(id);
      this.isDirty = true;
    },
  },
  created() {
    this.debouncedSearchKeyUpdate = debounce(this.setSearchKey, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    setSearchKey(value) {
      this.$emit('searchStarted', value);
    },
    handleItemClick(item) {
      this.localSelectedItem = item;
      if (!this.multiSelect) {
        this.$emit('updateValue', item);
      } else {
        this.isDirty = true;
        this.$emit('updateSelected', this.localSelectedItem);
        this.clearSearch();
      }
    },
    clearSearch() {
      if (this.clearSearchOnItemSelect) {
        this.setSearchKey('');
        this.$refs.listbox.$refs.searchBox.clearInput();
      }
    },
    onListboxShown() {
      this.$emit('dropdownShown');
    },
    onListboxHide() {
      this.isEditing = false;
      this.$emit('dropdownHidden');
      if (this.multiSelect && this.isDirty) {
        this.$emit('updateValue', this.localSelectedItem);
      }
    },
    unassignValue() {
      this.localSelectedItem = this.multiSelect ? [] : null;
      this.isEditing = false;
      this.$emit('updateValue', this.localSelectedItem);
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-flex gl-items-center gl-gap-3">
      <!-- hide header when editing, since we then have a form label. Keep it reachable for screenreader nav  -->
      <h3 :class="{ 'gl-sr-only': isEditing }" class="gl-heading-5 !gl-mb-0">
        {{ dropdownLabel }}
      </h3>
      <gl-loading-icon v-if="updateInProgress" />
      <gl-button
        v-if="canUpdate && !isEditing"
        data-testid="edit-button"
        category="tertiary"
        size="small"
        class="shortcut-sidebar-dropdown-toggle gl-ml-auto gl-flex-shrink-0"
        :disabled="updateInProgress"
        @click="isEditing = true"
        >{{ $options.i18n.editButtonLabel }}</gl-button
      >
    </div>
    <gl-form v-if="isEditing">
      <div class="gl-flex gl-items-center gl-justify-between">
        <label :for="inputId" class="gl-heading-5 !gl-mb-0">{{ dropdownLabel }}</label>
        <gl-button
          data-testid="apply-button"
          category="tertiary"
          size="small"
          class="gl-flex-shrink-0"
          :disabled="updateInProgress"
          @click="isEditing = false"
          >{{ $options.i18n.applyButtonLabel }}</gl-button
        >
      </div>
      <slot name="body">
        <gl-collapsible-listbox
          :id="inputId"
          ref="listbox"
          class="work-item-sidebar-dropdown"
          :multiple="multiSelect"
          :searchable="searchable"
          start-opened
          block
          is-check-centered
          :infinite-scroll="infiniteScroll"
          :searching="loading"
          :header-text="headerText"
          :toggle-text="toggleText"
          :no-results-text="$options.i18n.noMatchingResults"
          :items="listItems"
          :selected="localSelectedItem"
          :reset-button-label="resetButton"
          :infinite-scroll-loading="infiniteScrollLoading"
          @reset="unassignValue"
          @search="debouncedSearchKeyUpdate"
          @select="handleItemClick"
          @shown="onListboxShown"
          @hidden="onListboxHide"
          @bottom-reached="$emit('bottomReached')"
        >
          <template #list-item="{ item }">
            <slot name="list-item" :item="item">{{ item.text }}</slot>
          </template>
          <template v-if="showFooter" #footer>
            <div class="gl-border-t-1 gl-border-t-dropdown !gl-p-2 gl-border-t-solid">
              <slot name="footer"></slot>
            </div>
          </template>
        </gl-collapsible-listbox>
      </slot>
    </gl-form>
    <slot v-else-if="hasValue" name="readonly"></slot>
    <slot v-else name="none">
      <span class="gl-text-subtle">{{ $options.i18n.none }}</span>
    </slot>
  </div>
</template>
