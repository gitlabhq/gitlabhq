<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { debounce, isEmpty } from 'lodash';
import { keysFor } from '~/behaviors/shortcuts/keybindings';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { sanitize } from '~/lib/dompurify';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { __, sprintf } from '~/locale';
import WorkItemSidebarWidget from './work_item_sidebar_widget.vue';

export default {
  components: {
    GlCollapsibleListbox,
    WorkItemSidebarWidget,
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
    searchPlaceholder: {
      type: String,
      required: false,
      default: __('Search'),
    },
    shortcut: {
      type: Object,
      required: false,
      default: () => ({}),
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
      return this.resetButtonLabel || __('Clear');
    },
    toggleText() {
      return !this.toggleDropdownText && !this.hasValue
        ? sprintf(__(`No %{label}`), { label: this.dropdownLabel.toLowerCase() })
        : this.toggleDropdownText;
    },
    disableShortcuts() {
      return shouldDisableShortcuts() || Object.keys(this.shortcut).length === 0;
    },
    shortcutDescription() {
      return this.disableShortcuts ? null : this.shortcut.description;
    },
    shortcutKey() {
      return this.disableShortcuts ? null : keysFor(this.shortcut)[0];
    },
    tooltipText() {
      const description = this.shortcutDescription;
      const key = this.shortcutKey;
      return this.disableShortcuts
        ? null
        : sanitize(`${description} <kbd class="flat gl-ml-1" aria-hidden=true>${key}</kbd>`);
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
  <work-item-sidebar-widget
    :can-update="canUpdate"
    :is-editing="isEditing"
    :is-updating="updateInProgress"
    :tooltip-text="tooltipText"
    @startEditing="isEditing = true"
    @stopEditing="isEditing = false"
  >
    <template #title>
      {{ dropdownLabel }}
    </template>
    <template #content>
      <slot v-if="hasValue" name="readonly"></slot>
      <slot v-else name="none">
        <span class="gl-text-subtle">{{ s__('WorkItem|None') }}</span>
      </slot>
    </template>
    <template #editing-content>
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
          :search-placeholder="searchPlaceholder"
          :no-results-text="s__('WorkItem|No matching results')"
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
    </template>
  </work-item-sidebar-widget>
</template>
