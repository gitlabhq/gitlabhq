<script>
import { GlCollapsibleListbox, GlSearchBoxByType } from '@gitlab/ui';
import { parseBoolean, convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { createAlert } from '~/alert';
import { __, sprintf } from '~/locale';
import {
  fetchProjectGroups,
  fetchAllGroups,
  fetchGroupsWithProjectAccess,
  fetchProjects,
  fetchUsers,
  fetchAvailableDeployKeys,
} from '~/vue_shared/components/list_selector/api';
import { CONFIG } from './constants';

const I18N = {
  allGroups: __('All groups'),
  projectGroups: __('Project groups'),
  apiErrorMessage: __('An error occurred while fetching. Please try again.'),
};

/**
 * Renders a selector and displays a list of selected items.
 * Selected items can be:
 * - users
 * - projects
 * - groups
 * - deploy keys
 *
 *
 * For groups type, there are three different APIs you can use:
 * - `fetchAllGroups()` (default)
 *   - uses GraphQL `groupsAutocompleteQuery`
 * - `fetchProjectGroups()`
 *   - when `isProjectNamespace` equals `true`,
 *   - uses `Api.projectGroups()` with parameters `{with_shared: true, shared_min_access_level: ACCESS_LEVEL_REPORTER_INTEGER}`
 * - `fetchGroupsWithProjectAccess()`
 *   - when `isGroupsWithProjectAccess` equals `true`,
 *   - GET Request `autocomplete/project_groups.json` to fetch groups invited to the project
 *
 */

export default {
  name: 'ListSelector',
  i18n: I18N,
  components: {
    GlSearchBoxByType,
    GlCollapsibleListbox,
    CrudComponent,
  },
  props: {
    type: {
      type: String,
      required: true,
    },
    selectedItems: {
      type: Array,
      required: false,
      default: () => [],
    },
    projectPath: {
      type: String,
      required: false,
      default: null,
    },
    groupPath: {
      type: String,
      required: false,
      default: null,
    },
    projectId: {
      type: Number,
      required: false,
      default: null,
    },
    autofocus: {
      type: Boolean,
      required: false,
      default: false,
    },
    usersQueryOptions: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    disableNamespaceDropdown: {
      type: Boolean,
      required: false,
      default: false,
    },
    isProjectScoped: {
      type: Boolean,
      required: false,
      default: false,
    },
    isGroupsWithProjectAccess: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      searchValue: '',
      isProjectNamespace: this.isProjectScoped ? 'true' : 'false',
      selected: [],
      items: [],
      isLoading: false,
    };
  },
  computed: {
    config() {
      return CONFIG[this.type];
    },
    showNamespaceDropdown() {
      return this.config.showNamespaceDropdown && !this.disableNamespaceDropdown;
    },
    namespaceDropdownText() {
      return parseBoolean(this.isProjectNamespace)
        ? this.$options.i18n.projectGroups
        : this.$options.i18n.allGroups;
    },
    searchPlaceholder() {
      return sprintf(__('Search to add %{title}'), {
        title: this.config.title.toLowerCase(),
      });
    },
    emptyPlaceholder() {
      return sprintf(__('No %{title} have been added.'), {
        title: this.config.title.toLowerCase(),
      });
    },
    filteredItems() {
      // Filter out selected items
      return this.items.filter(
        (item) =>
          !this.selectedItems.some((selectedItem) => {
            return selectedItem.id === item.id;
          }),
      );
    },
  },
  methods: {
    async handleSearchInput(search = this.searchValue) {
      this.$refs.results.open();
      this.$refs.search.focusInput();

      const searchMethod = {
        users: this.fetchUsersBySearchTerm,
        groups: this.fetchGroupsBySearchTerm,
        deployKeys: this.fetchDeployKeysBySearchTerm,
        projects: this.fetchProjectsBySearchTerm,
      };

      try {
        this.isLoading = true;
        this.items = await searchMethod[this.type](search);
      } catch (e) {
        createAlert({
          message: this.$options.i18n.apiErrorMessage,
        });
      } finally {
        this.isLoading = false;
      }
    },
    async fetchUsersBySearchTerm(search) {
      return fetchUsers(this.projectPath, search, this.usersQueryOptions);
    },
    async fetchGroupsBySearchTerm(search) {
      let groups = [];
      if (parseBoolean(this.isProjectNamespace)) {
        groups = await fetchProjectGroups(this.projectPath, search);
      } else if (this.isGroupsWithProjectAccess) {
        groups = await fetchGroupsWithProjectAccess(this.projectId, search);
      } else {
        groups = await fetchAllGroups(this.$apollo, search);
      }

      return groups;
    },
    fetchDeployKeysBySearchTerm(search) {
      return fetchAvailableDeployKeys(this.$apollo, this.projectPath, search);
    },
    fetchProjectsBySearchTerm(search) {
      return fetchProjects(search);
    },
    getItemByKey(key) {
      return this.items.find((item) => {
        return item[this.config.filterKey] === key;
      });
    },
    handleSelectItem(key) {
      this.$emit('select', this.getItemByKey(key));
      this.$refs.results.close();
    },
    handleDeleteItem(key) {
      this.$emit('delete', key);
    },
    handleSelectNamespace() {
      this.items = [];
      this.searchValue = '';
    },
    convertToCamelCase(data) {
      return convertObjectPropsToCamelCase(data);
    },
  },
  namespaceOptions: [
    { text: I18N.projectGroups, value: 'true' },
    { text: I18N.allGroups, value: 'false' },
  ],
};
</script>

<template>
  <crud-component :title="config.title" :count="selectedItems.length" :icon="config.icon">
    <div class="gl-flex gl-gap-3" :class="{ 'gl-mb-4': selectedItems.length }">
      <gl-collapsible-listbox
        ref="results"
        class="list-selector gl-block gl-grow"
        :items="filteredItems"
        @select="handleSelectItem"
        @shown="handleSearchInput"
      >
        <template #toggle>
          <gl-search-box-by-type
            ref="search"
            v-model="searchValue"
            :placeholder="searchPlaceholder"
            :autofocus="autofocus"
            debounce="500"
            :is-loading="isLoading"
            @input="handleSearchInput"
          />
        </template>

        <template #list-item="{ item }">
          <component :is="config.component" :data="item" />
        </template>
      </gl-collapsible-listbox>

      <gl-collapsible-listbox
        v-if="showNamespaceDropdown"
        v-model="isProjectNamespace"
        :toggle-text="namespaceDropdownText"
        :items="$options.namespaceOptions"
        data-testid="namespace-dropdown"
        @select="handleSelectNamespace"
      />
    </div>

    <div v-if="selectedItems.length">
      <component
        :is="config.component"
        v-for="(item, index) of selectedItems"
        :key="index"
        :class="{ 'gl-border-t': index > 0 }"
        class="gl-p-3"
        :data="convertToCamelCase(item)"
        can-delete
        @delete="handleDeleteItem"
      />
    </div>

    <div v-else class="gl-mt-5 gl-text-subtle">{{ emptyPlaceholder }}</div>
  </crud-component>
</template>
