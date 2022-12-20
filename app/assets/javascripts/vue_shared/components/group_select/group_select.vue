<script>
import { debounce } from 'lodash';
import { GlCollapsibleListbox } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import Api from '~/api';
import { __ } from '~/locale';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { createAlert } from '~/flash';
import { groupsPath } from './utils';
import {
  TOGGLE_TEXT,
  FETCH_GROUPS_ERROR,
  FETCH_GROUP_ERROR,
  QUERY_TOO_SHORT_MESSAGE,
} from './constants';

const MINIMUM_QUERY_LENGTH = 3;

export default {
  components: {
    GlCollapsibleListbox,
  },
  props: {
    inputName: {
      type: String,
      required: true,
    },
    inputId: {
      type: String,
      required: true,
    },
    initialSelection: {
      type: String,
      required: false,
      default: null,
    },
    clearable: {
      type: Boolean,
      required: false,
      default: false,
    },
    parentGroupID: {
      type: String,
      required: false,
      default: null,
    },
    groupsFilter: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      pristine: true,
      searching: false,
      searchString: '',
      groups: [],
      selectedValue: null,
      selectedText: null,
    };
  },
  computed: {
    selected: {
      set(value) {
        this.selectedValue = value;
        this.selectedText =
          value === null ? null : this.groups.find((group) => group.value === value).full_name;
      },
      get() {
        return this.selectedValue;
      },
    },
    toggleText() {
      return this.selectedText ?? this.$options.i18n.toggleText;
    },
    inputValue() {
      return this.selectedValue ? this.selectedValue : '';
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
  created() {
    this.fetchInitialSelection();
  },
  methods: {
    search: debounce(function debouncedSearch(searchString) {
      this.searchString = searchString;
      if (this.isSearchQueryTooShort) {
        this.groups = [];
      } else {
        this.fetchGroups(searchString);
      }
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS),
    async fetchGroups(searchString = '') {
      this.searching = true;

      try {
        const { data } = await axios.get(
          Api.buildUrl(groupsPath(this.groupsFilter, this.parentGroupID)),
          {
            params: {
              search: searchString,
            },
          },
        );
        const groups = data.length ? data : data.results || [];

        this.groups = groups.map((group) => ({
          ...group,
          value: String(group.id),
        }));

        this.searching = false;
      } catch (error) {
        createAlert({
          message: FETCH_GROUPS_ERROR,
          error,
          parent: this.$el,
        });
      }
    },
    async fetchInitialSelection() {
      if (!this.initialSelection) {
        this.pristine = false;
        return;
      }
      this.searching = true;
      try {
        const group = await Api.group(this.initialSelection);
        this.selectedValue = this.initialSelection;
        this.selectedText = group.full_name;
        this.pristine = false;
        this.searching = false;
      } catch (error) {
        createAlert({
          message: FETCH_GROUP_ERROR,
          error,
          parent: this.$el,
        });
      }
    },
    onShown() {
      if (!this.searchString && !this.groups.length) {
        this.fetchGroups();
      }
    },
    onReset() {
      this.selected = null;
    },
  },
  i18n: {
    toggleText: TOGGLE_TEXT,
    selectGroup: __('Select a group'),
    reset: __('Reset'),
    noResultsText: __('No results found.'),
    searchQueryTooShort: QUERY_TOO_SHORT_MESSAGE,
  },
};
</script>

<template>
  <div>
    <gl-collapsible-listbox
      ref="listbox"
      v-model="selected"
      :header-text="$options.i18n.selectGroup"
      :reset-button-label="$options.i18n.reset"
      :toggle-text="toggleText"
      :loading="searching && pristine"
      :searching="searching"
      :items="groups"
      :no-results-text="noResultsText"
      searchable
      @shown="onShown"
      @search="search"
      @reset="onReset"
    >
      <template #list-item="{ item }">
        <div class="gl-font-weight-bold">
          {{ item.full_name }}
        </div>
        <div class="gl-text-gray-300">{{ item.full_path }}</div>
      </template>
    </gl-collapsible-listbox>
    <div class="flash-container"></div>
    <input :id="inputId" data-testid="input" type="hidden" :name="inputName" :value="inputValue" />
  </div>
</template>
