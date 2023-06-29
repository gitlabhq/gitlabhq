<script>
import { GlAvatarLabeled, GlCollapsibleListbox } from '@gitlab/ui';
import { debounce } from 'lodash';
import { s__ } from '~/locale';
import { getGroups, getDescendentGroups } from '~/rest_api';
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
    };
  },
  computed: {
    toggleText() {
      return this.selectedGroup.name || this.$options.i18n.dropdownText;
    },
    isFetchResultEmpty() {
      return this.groups.length === 0;
    },
  },
  mounted() {
    this.retrieveGroups();
  },
  methods: {
    retrieveGroups: debounce(function debouncedRetrieveGroups() {
      this.isFetching = true;
      return this.fetchGroups()
        .then((response) => {
          this.groups = this.processGroups(response);
          this.isFetching = false;
        })
        .catch(() => {
          this.isFetching = false;
        });
    }, SEARCH_DELAY),
    processGroups(response) {
      const rawGroups = response.map((group) => ({
        // `value` is needed for `GlCollapsibleListbox`
        value: group.id,
        id: group.id,
        name: group.full_name,
        path: group.path,
        avatarUrl: group.avatar_url,
      }));

      return this.filterOutInvalidGroups(rawGroups);
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
    fetchGroups() {
      switch (this.groupsFilter) {
        case GROUP_FILTERS.DESCENDANT_GROUPS:
          return getDescendentGroups(
            this.parentGroupId,
            this.searchTerm,
            this.$options.defaultFetchOptions,
          );
        default:
          return getGroups(this.searchTerm, this.$options.defaultFetchOptions);
      }
    },
  },
  i18n: {
    dropdownText: s__('GroupSelect|Select a group'),
    searchPlaceholder: s__('GroupSelect|Search groups'),
    emptySearchResult: s__('GroupSelect|No matching results'),
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
