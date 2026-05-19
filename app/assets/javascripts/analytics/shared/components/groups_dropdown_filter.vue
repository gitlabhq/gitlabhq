<script>
import { GlCollapsibleListbox, GlAvatar, GlButton, GlIcon, GlTruncate } from '@gitlab/ui';
import { debounce, unionBy } from 'lodash-es';
import { filterBySearchTerm, mapItemToListboxFormat } from '~/analytics/shared/utils';
import { MIN_SEARCH_CHARS } from '~/analytics/shared/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { sprintf, s__, __ } from '~/locale';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import GetGroupsQuery from '../graphql/groups.query.graphql';

const sortByGroupName = (groups = []) => groups.sort((a, b) => a.name.localeCompare(b.name));

const defaultQueryParams = {
  first: 20,
  topLevelOnly: false,
};

export default {
  name: 'GroupsDropdownFilter',
  components: {
    GlCollapsibleListbox,
    GlAvatar,
    GlButton,
    GlIcon,
    GlTruncate,
  },
  props: {
    multiSelect: {
      type: Boolean,
      required: false,
      default: false,
    },
    queryParams: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    defaultGroups: {
      type: Array,
      required: false,
      default: () => [],
    },
    loadingDefaultGroups: {
      type: Boolean,
      required: false,
      default: false,
    },
    toggleClasses: {
      type: String,
      required: false,
      default: '',
    },
  },
  emits: ['selected'],
  data() {
    return {
      groups: [],
      selectedGroups: this.defaultGroups || [],
      searchTerm: '',
      isDirty: false,
    };
  },
  apollo: {
    groups: {
      query: GetGroupsQuery,
      variables() {
        return {
          ...defaultQueryParams,
          search: this.searchTerm,
          ...this.queryParams,
        };
      },
      update({ groups }) {
        return groups?.nodes || [];
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.groups.loading;
    },
    selectedGroupsLabel() {
      if (this.isOnlyOneGroupSelected) {
        return this.selectedGroups[0].name;
      }
      if (this.selectedGroups.length > 0) {
        return sprintf(s__('AnalyticsDashboards|%{count} groups selected'), {
          count: this.selectedGroups.length,
        });
      }

      return __('Select a group');
    },
    isOnlyOneGroupSelected() {
      return this.selectedGroups.length === 1;
    },
    selectedGroupIds() {
      return this.selectedGroups.map((p) => p.id);
    },
    selectedListBoxItems() {
      return this.multiSelect ? this.selectedGroupIds : this.selectedGroupIds[0];
    },
    hasSelectedGroups() {
      return Boolean(this.selectedGroups.length);
    },
    availableGroups() {
      return filterBySearchTerm(this.groups, this.searchTerm);
    },
    selectedItems() {
      return sortByGroupName(this.selectedGroups);
    },
    unselectedItems() {
      return this.availableGroups.filter(({ id }) => !this.selectedGroupIds.includes(id));
    },
    selectedGroupOptions() {
      return this.selectedItems.map(mapItemToListboxFormat);
    },
    unSelectedGroupOptions() {
      return this.unselectedItems.map(mapItemToListboxFormat);
    },
    listBoxItems() {
      if (!this.hasSelectedGroups) {
        return this.unSelectedGroupOptions;
      }

      return [
        {
          text: __('Selected'),
          options: this.selectedGroupOptions,
        },
        {
          text: __('Unselected'),
          options: this.unSelectedGroupOptions,
        },
      ];
    },
  },
  watch: {
    searchTerm() {
      this.search();
    },
    defaultGroups(groups) {
      this.selectedGroups = [...groups];
    },
  },
  mounted() {
    this.search();
  },
  methods: {
    handleUpdatedSelectedGroups() {
      this.$emit('selected', this.selectedGroups);
    },
    search: debounce(function debouncedSearch() {
      this.$apollo.queries.groups.refetch();
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS),
    getSelectedGroups(groups, selectedGroupIds) {
      return groups.filter(({ id }) => selectedGroupIds.includes(id));
    },
    setSelectedGroups(payload) {
      if (this.multiSelect) {
        this.selectedGroups = payload;
      } else {
        this.selectedGroups = this.isGroupSelected(payload) ? [] : [payload];
      }
    },
    onClick(groupId) {
      const group = this.availableGroups.find(({ id }) => id === groupId);
      this.setSelectedGroups(group);
      this.handleUpdatedSelectedGroups();
    },
    onMultiSelectClick(groupIds) {
      const newlySelectedGroups = this.getSelectedGroups(this.availableGroups, groupIds);
      const selectedGroups = this.getSelectedGroups(this.selectedGroups, groupIds);

      this.setSelectedGroups(unionBy(newlySelectedGroups, selectedGroups, 'id'));
      this.isDirty = true;
    },
    onSelected(payload) {
      if (this.multiSelect) {
        this.onMultiSelectClick(payload);
      } else {
        this.onClick(payload);
      }
    },
    onHide() {
      if (this.multiSelect && this.isDirty) {
        this.handleUpdatedSelectedGroups();
      }
      this.searchTerm = '';
      this.isDirty = false;
    },
    onClearAll() {
      if (this.hasSelectedGroups) {
        this.isDirty = true;
      }
      this.selectedGroups = [];
      this.handleUpdatedSelectedGroups();
    },
    isGroupSelected(group) {
      return this.selectedGroupIds.includes(group.id);
    },
    getEntityId(group) {
      return getIdFromGraphQLId(group.id);
    },
    setSearchTerm(val) {
      if (val && val.length >= MIN_SEARCH_CHARS) {
        this.searchTerm = val;
        return;
      }

      this.searchTerm = '';
    },
  },
  AVATAR_SHAPE_OPTION_RECT,
};
</script>

<template>
  <gl-collapsible-listbox
    ref="groupsDropdown"
    :header-text="__('Groups')"
    :items="listBoxItems"
    :reset-button-label="__('Clear All')"
    :multiple="multiSelect"
    :no-results-text="__('No matching results')"
    :selected="selectedListBoxItems"
    :searching="isLoading"
    searchable
    @hidden="onHide"
    @reset="onClearAll"
    @search="setSearchTerm"
    @select="onSelected"
  >
    <template #toggle>
      <gl-button
        :loading="loadingDefaultGroups"
        button-text-classes="gl-w-full gl-justify-between gl-flex gl-shadow-none gl-mb-0"
        :class="['dropdown-groups', toggleClasses]"
      >
        <gl-avatar
          v-if="isOnlyOneGroupSelected"
          :src="selectedGroups[0].avatarUrl"
          :entity-id="getEntityId(selectedGroups[0])"
          :entity-name="selectedGroups[0].name"
          :size="16"
          :shape="$options.AVATAR_SHAPE_OPTION_RECT"
          :alt="selectedGroups[0].name"
          class="gl-mr-2 gl-inline-flex gl-shrink-0 gl-align-middle"
        />
        <gl-truncate :text="selectedGroupsLabel" class="gl-min-w-0 gl-grow" />
        <gl-icon class="gl-ml-2 gl-shrink-0" name="chevron-down" />
      </gl-button>
    </template>
    <template #list-item="{ item }">
      <div class="gl-flex">
        <gl-avatar
          class="gl-mr-2 gl-align-middle"
          :alt="item.name"
          :size="16"
          :entity-id="getEntityId(item)"
          :entity-name="item.name"
          :src="item.avatarUrl"
          :shape="$options.AVATAR_SHAPE_OPTION_RECT"
        />
        <div>
          <div data-testid="group-name">{{ item.name }}</div>
          <div class="gl-text-subtle" data-testid="group-full-path">
            {{ item.fullPath }}
          </div>
        </div>
      </div>
    </template>
  </gl-collapsible-listbox>
</template>
