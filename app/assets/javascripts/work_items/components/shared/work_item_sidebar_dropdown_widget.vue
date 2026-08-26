<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { debounce, isEmpty } from 'lodash-es';
import { keysFor } from '~/behaviors/shortcuts/keybindings';
import { keyboardShortcutsDisabled } from '~/behaviors/shortcuts/shortcuts_disabled';
import { sanitize, titleInLinkSafeHtmlConfig } from '~/lib/dompurify';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { __, sprintf } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import WorkItemSidebarWidget from './work_item_sidebar_widget.vue';

export default {
  name: 'WorkItemSidebarDropdownWidget',
  components: {
    GlCollapsibleListbox,
    WorkItemSidebarWidget,
  },
  directives: {
    SafeHtml,
  },
  props: {
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    // Declared as a prop (rather than left in $attrs) and forwarded explicitly
    // below, so it does not leak into WorkItemSidebarWidget's own $attrs.
    dataTestid: {
      type: String,
      required: false,
      default: null,
    },
    dropdownLabel: {
      type: String,
      required: true,
    },
    dropdownName: {
      type: String,
      required: true,
    },
    disabledItems: {
      type: Array,
      required: false,
      default: () => [],
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
    noResetButton: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['dropdown-hidden', 'dropdown-shown', 'search-started', 'update-selected', 'update-value'],
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
      return this.noResetButton ? null : this.resetButtonLabel || __('Clear');
    },
    toggleText() {
      return !this.toggleDropdownText && !this.hasValue
        ? sprintf(__(`No %{label}`), { label: this.dropdownLabel.toLowerCase() })
        : this.toggleDropdownText;
    },
    disableShortcuts() {
      return keyboardShortcutsDisabled() || Object.keys(this.shortcut).length === 0;
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
    createdLabelId() {
      this.isDirty = true;
    },
  },
  created() {
    this.debouncedSearchKeyUpdate = debounce(this.setSearchKey, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    setSearchKey(value) {
      this.$emit('search-started', value);
    },
    handleItemClick(item) {
      // Handle both single and multi-select cases
      const itemArray = Array.isArray(item) ? item : [item];
      const itemsToUpdate = itemArray.filter((i) => !this.disabledItems.includes(i));

      // For single select, unwrap the array
      const finalValue = this.multiSelect ? itemsToUpdate : itemsToUpdate[0];

      this.localSelectedItem = finalValue;
      if (!this.multiSelect) {
        this.$emit('update-value', finalValue);
      } else {
        this.isDirty = true;
        this.$emit('update-selected', this.localSelectedItem);
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
      this.$emit('dropdown-shown');
    },
    onListboxHide() {
      this.isEditing = false;
      this.$emit('dropdown-hidden');
      if (this.multiSelect && this.isDirty) {
        this.$emit('update-value', this.localSelectedItem);
      }
    },
    unassignValue() {
      this.localSelectedItem = this.multiSelect ? [] : null;
      this.isEditing = false;
      this.$emit('update-value', this.localSelectedItem);
    },
  },
  titleInLinkSafeHtmlConfig,
};
</script>

<template>
  <work-item-sidebar-widget
    :can-update="canUpdate"
    :data-testid="dataTestid"
    :is-editing="isEditing"
    :is-updating="updateInProgress"
    :tooltip-text="tooltipText"
    @start-editing="isEditing = true"
    @stop-editing="isEditing = false"
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
          :searching="loading"
          :header-text="headerText"
          :toggle-text="toggleText"
          :search-placeholder="searchPlaceholder"
          :no-results-text="s__('WorkItem|No matching results')"
          :items="listItems"
          :selected="localSelectedItem"
          :reset-button-label="resetButton"
          @reset="unassignValue"
          @search="debouncedSearchKeyUpdate"
          @select="handleItemClick"
          @shown="onListboxShown"
          @hidden="onListboxHide"
        >
          <template #list-item="{ item }">
            <slot name="list-item" :item="item">
              <span
                v-if="item.textHtml"
                v-safe-html:[$options.titleInLinkSafeHtmlConfig]="item.textHtml"
              ></span>
              <span v-else>{{ item.text }}</span>
            </slot>
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
