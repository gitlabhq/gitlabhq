<script>
import { GlAvatarLabeled, GlCollapsibleListbox } from '@gitlab/ui';
import axios from 'axios';
import { debounce } from 'lodash';
import { s__ } from '~/locale';
import { getGroups, getDescendentGroups, getProjectShareLocations } from '~/rest_api';
import { normalizeHeaders, parseIntPagination } from '~/lib/utils/common_utils';
import { SEARCH_DELAY, GROUP_FILTERS } from '../constants';

export default {
  name: 'GroupSelect',
  components: {
    GlAvatarLabeled,
    GlCollapsibleListbox,
  },
  model: {
    prop: 'selectedGroup',
  },
  props: {
    selectedGroup: {
      type: Object,
      required: true,
    },
    groupsFilter: {
      type: String,
      required: false,
      default: GROUP_FILTERS.ALL,
    },
    isProject: {
      type: Boolean,
      required: true,
    },
    sourceId: {
      type: String,
      required: true,
    },
    parentGroupId: {
      type: Number,
      required: false,
      default: null,
    },
    invalidGroups: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      isFetching: false,
      groups: [],
      searchTerm: '',
      pagination: {},
      infiniteScrollLoading: false,
      activeApiRequestAbortController: null,
    };
  },
  computed: {
    toggleText() {
      return this.selectedGroup.name || this.$options.i18n.dropdownText;
    },
    isFetchResultEmpty() {
      return this.groups.length === 0;
    },
    infiniteScroll() {
      return Boolean(this.pagination.nextPage);
    },
  },
  mounted() {
    this.retrieveGroups();
  },
  methods: {
    retrieveGroups: debounce(async function debouncedRetrieveGroups() {
      this.isFetching = true;
      try {
        const response = await this.fetchGroups();
        this.pagination = this.processPagination(response);
        this.groups = this.processGroups(response);
        this.isFetching = false;
      } catch (e) {
        this.onApiError(e);
      }
    }, SEARCH_DELAY),
    processGroups({ data }) {
      const rawGroups = data.map((group) => ({
        // `value` is needed for `GlCollapsibleListbox`
        value: group.id,
        id: group.id,
        name: group.full_name,
        path: group.full_path,
        avatarUrl: group.avatar_url,
      }));

      return this.filterOutInvalidGroups(rawGroups);
    },
    processPagination({ headers }) {
      return parseIntPagination(normalizeHeaders(headers));
    },
    filterOutInvalidGroups(groups) {
      return groups.filter((group) => this.invalidGroups.indexOf(group.id) === -1);
    },
    onSelect(id) {
      this.$emit('input', this.groups.find((group) => group.value === id) || {});
    },
    onSearch(searchTerm) {
      this.searchTerm = searchTerm;
      this.retrieveGroups();
    },
    fetchGroups(options = {}) {
      if (this.activeApiRequestAbortController !== null) {
        this.activeApiRequestAbortController.abort();
      }

      this.activeApiRequestAbortController = new AbortController();

      const axiosConfig = {
        signal: this.activeApiRequestAbortController.signal,
      };

      if (this.isProject) {
        return this.fetchGroupsNew(options, axiosConfig);
      }

      return this.fetchGroupsLegacy(options, axiosConfig);
    },
    fetchGroupsNew(options, axiosConfig) {
      return getProjectShareLocations(
        this.sourceId,
        { search: this.searchTerm, ...options },
        axiosConfig,
      );
    },
    fetchGroupsLegacy(options, axiosConfig) {
      const combinedOptions = {
        ...this.$options.defaultFetchOptions,
        ...options,
      };

      switch (this.groupsFilter) {
        case GROUP_FILTERS.DESCENDANT_GROUPS:
          return getDescendentGroups(
            this.parentGroupId,
            this.searchTerm,
            combinedOptions,
            undefined,
            axiosConfig,
          );
        default:
          return getGroups(this.searchTerm, combinedOptions, undefined, axiosConfig);
      }
    },
    async onBottomReached() {
      this.infiniteScrollLoading = true;

      try {
        const response = await this.fetchGroups({ page: this.pagination.page + 1 });
        this.pagination = this.processPagination(response);
        this.groups.push(...this.processGroups(response));
        this.infiniteScrollLoading = false;
      } catch (e) {
        this.onApiError(e);
      }
    },
    onApiError(error) {
      if (axios.isCancel(error)) return;
      this.isFetching = false;
      this.infiniteScrollLoading = false;
      this.$emit('error', this.$options.i18n.errorMessage);
    },
  },
  i18n: {
    dropdownText: s__('GroupSelect|Select a group'),
    searchPlaceholder: s__('GroupSelect|Search groups'),
    emptySearchResult: s__('GroupSelect|No matching results'),
    errorMessage: s__(
      'GroupSelect|An error occurred fetching the groups. Please refresh the page to try again.',
    ),
  },
  defaultFetchOptions: {
    exclude_internal: true,
    active: true,
    order_by: 'similarity',
  },
};
</script>
<template>
  <div>
    <gl-collapsible-listbox
      data-testid="group-select-dropdown"
      :selected="selectedGroup.value"
      :items="groups"
      :toggle-text="toggleText"
      searchable
      :search-placeholder="$options.i18n.searchPlaceholder"
      block
      fluid-width
      is-check-centered
      :searching="isFetching"
      :no-results-text="$options.i18n.emptySearchResult"
      :infinite-scroll="infiniteScroll"
      :infinite-scroll-loading="infiniteScrollLoading"
      :total-items="pagination.total"
      @bottom-reached="onBottomReached"
      @select="onSelect"
      @search="onSearch"
    >
      <template #list-item="{ item }">
        <gl-avatar-labeled
          :label="item.name"
          :src="item.avatarUrl"
          :entity-id="item.value"
          :entity-name="item.name"
          :size="32"
        />
      </template>
    </gl-collapsible-listbox>
  </div>
</template>
