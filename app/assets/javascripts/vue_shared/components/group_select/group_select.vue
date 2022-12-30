<script>
import { debounce } from 'lodash';
import { GlAlert, GlCollapsibleListbox } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import axios from '~/lib/utils/axios_utils';
import { normalizeHeaders, parseIntPagination } from '~/lib/utils/common_utils';
import Api from '~/api';
import { __ } from '~/locale';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { groupsPath } from './utils';
import {
  TOGGLE_TEXT,
  FETCH_GROUPS_ERROR,
  FETCH_GROUP_ERROR,
  QUERY_TOO_SHORT_MESSAGE,
} from './constants';

const MINIMUM_QUERY_LENGTH = 3;
const GROUPS_PER_PAGE = 20;

export default {
  components: {
    GlAlert,
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
      hasMoreGroups: true,
      infiniteScrollLoading: false,
      searchString: '',
      groups: [],
      page: 1,
      selectedValue: null,
      selectedText: null,
      errorMessage: '',
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
        this.fetchGroups();
      }
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS),
    async fetchGroups(page = 1) {
      if (page === 1) {
        this.searching = true;
        this.groups = [];
        this.hasMoreGroups = true;
      } else {
        this.infiniteScrollLoading = true;
      }

      try {
        const { data, headers } = await axios.get(
          Api.buildUrl(groupsPath(this.groupsFilter, this.parentGroupID)),
          {
            params: {
              search: this.searchString,
              per_page: GROUPS_PER_PAGE,
              page,
            },
          },
        );
        const groups = data.length ? data : data.results || [];

        this.groups.push(
          ...groups.map((group) => ({
            ...group,
            value: String(group.id),
          })),
        );

        const { totalPages } = parseIntPagination(normalizeHeaders(headers));
        if (page === totalPages) {
          this.hasMoreGroups = false;
        }

        this.page = page;
        this.searching = false;
        this.infiniteScrollLoading = false;
      } catch (error) {
        this.handleError({ message: FETCH_GROUPS_ERROR, error });
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
        this.handleError({ message: FETCH_GROUP_ERROR, error });
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
    onBottomReached() {
      this.fetchGroups(this.page + 1);
    },
    handleError({ message, error }) {
      Sentry.captureException(error);
      this.errorMessage = message;
    },
    dismissError() {
      this.errorMessage = '';
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
    <gl-alert v-if="errorMessage" class="gl-mb-3" variant="danger" @dismiss="dismissError">{{
      errorMessage
    }}</gl-alert>
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
      :infinite-scroll="hasMoreGroups"
      :infinite-scroll-loading="infiniteScrollLoading"
      searchable
      @shown="onShown"
      @search="search"
      @reset="onReset"
      @bottom-reached="onBottomReached"
    >
      <template #list-item="{ item }">
        <div class="gl-font-weight-bold">
          {{ item.full_name }}
        </div>
        <div class="gl-text-gray-300">{{ item.full_path }}</div>
      </template>
    </gl-collapsible-listbox>
    <input :id="inputId" data-testid="input" type="hidden" :name="inputName" :value="inputValue" />
  </div>
</template>
