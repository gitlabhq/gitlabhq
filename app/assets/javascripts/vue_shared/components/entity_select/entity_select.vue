<script>
import { debounce } from 'lodash';
import { GlFormGroup, GlCollapsibleListbox } from '@gitlab/ui';
import { __ } from '~/locale';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { RESET_LABEL, QUERY_TOO_SHORT_MESSAGE } from './constants';

const MINIMUM_QUERY_LENGTH = 3;

export default {
  components: {
    GlFormGroup,
    GlCollapsibleListbox,
  },
  props: {
    block: {
      type: Boolean,
      required: false,
      default: false,
    },
    label: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: false,
      default: '',
    },
    inputName: {
      type: String,
      required: true,
    },
    inputId: {
      type: String,
      required: true,
    },
    initialSelection: {
      type: [String, Number],
      required: false,
      default: null,
    },
    clearable: {
      type: Boolean,
      required: false,
      default: false,
    },
    headerText: {
      type: String,
      required: true,
    },
    defaultToggleText: {
      type: String,
      required: true,
    },
    fetchItems: {
      type: Function,
      required: true,
    },
    fetchInitialSelection: {
      type: Function,
      required: false,
      default: null,
    },
    toggleClass: {
      type: [String, Array, Object],
      required: false,
      default: '',
    },
  },
  data() {
    return {
      pristine: true,
      searching: false,
      hasMoreItems: true,
      infiniteScrollLoading: false,
      searchString: '',
      items: [],
      page: 1,
      selected: this.initialSelection || '',
      initialSelectedItem: {},
      errorMessage: '',
    };
  },
  computed: {
    selectedItem() {
      const item = this.items.find(({ value }) => value === this.selected);

      return item || this.initialSelectedItem;
    },
    toggleText() {
      return this.selectedItem?.text ?? this.defaultToggleText;
    },
    resetButtonLabel() {
      return this.clearable ? RESET_LABEL : '';
    },
    isSearchQueryTooShort() {
      return this.searchString && this.searchString.length < MINIMUM_QUERY_LENGTH;
    },
    noResultsText() {
      return this.isSearchQueryTooShort
        ? this.$options.i18n.searchQueryTooShort
        : this.$options.i18n.noResultsText;
    },
  },
  watch: {
    selected() {
      this.$emit('input', this.selectedItem);
    },
  },
  created() {
    this.getInitialSelection();
  },
  methods: {
    search: debounce(function debouncedSearch(searchString) {
      this.searchString = searchString;
      if (this.isSearchQueryTooShort) {
        this.items = [];
      } else {
        this.fetchEntities();
      }
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS),
    async fetchEntities(page = 1) {
      if (page === 1) {
        this.searching = true;
        this.items = [];
        this.hasMoreItems = true;
      } else {
        this.infiniteScrollLoading = true;
      }

      const { items, totalPages } = await this.fetchItems(this.searchString, page);

      this.items.push(...items);

      if (page === totalPages) {
        this.hasMoreItems = false;
      }

      this.page = page;
      this.searching = false;
      this.infiniteScrollLoading = false;
    },
    async getInitialSelection() {
      if (!this.initialSelection) {
        this.pristine = false;
        return;
      }

      if (!this.fetchInitialSelection) {
        throw new Error(
          '`initialSelection` is provided but lacks `fetchInitialSelectionText` to retrieve the corresponding text',
        );
      }

      this.searching = true;
      this.initialSelectedItem = await this.fetchInitialSelection(this.initialSelection);
      this.pristine = false;
      this.searching = false;
    },
    onShown() {
      if (!this.searchString && !this.items.length) {
        this.fetchEntities();
      }
    },
    onReset() {
      this.selected = null;
      this.$emit('input', {});
    },
    onBottomReached() {
      this.fetchEntities(this.page + 1);
    },
  },
  i18n: {
    noResultsText: __('No results found.'),
    searchQueryTooShort: QUERY_TOO_SHORT_MESSAGE,
  },
};
</script>

<template>
  <gl-form-group :label="label" :description="description">
    <slot name="error"></slot>
    <template v-if="Boolean($scopedSlots.label)" #label>
      <slot name="label"></slot>
    </template>
    <gl-collapsible-listbox
      ref="listbox"
      v-model="selected"
      :block="block"
      :header-text="headerText"
      :reset-button-label="resetButtonLabel"
      :toggle-text="toggleText"
      :loading="searching && pristine"
      :searching="searching"
      :items="items"
      :no-results-text="noResultsText"
      :infinite-scroll="hasMoreItems"
      :infinite-scroll-loading="infiniteScrollLoading"
      :toggle-class="toggleClass"
      searchable
      @shown="onShown"
      @search="search"
      @reset="onReset"
      @bottom-reached="onBottomReached"
    >
      <template #list-item="{ item }">
        <slot name="list-item" :item="item"></slot>
      </template>
    </gl-collapsible-listbox>
    <input :id="inputId" data-testid="input" type="hidden" :name="inputName" :value="selected" />
  </gl-form-group>
</template>
