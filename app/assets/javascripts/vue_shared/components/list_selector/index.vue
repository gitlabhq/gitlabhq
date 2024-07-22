<script>
import { GlCard, GlIcon, GlCollapsibleListbox, GlSearchBoxByType } from '@gitlab/ui';
import { parseBoolean, convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { createAlert } from '~/alert';
import { __, sprintf } from '~/locale';
import { ACCESS_LEVEL_REPORTER_INTEGER } from '~/access_level/constants';
import groupsAutocompleteQuery from '~/graphql_shared/queries/groups_autocomplete.query.graphql';
import Api from '~/api';
import { getProjects } from '~/rest_api';
import { CONFIG } from './constants';

const I18N = {
  allGroups: __('All groups'),
  projectGroups: __('Project groups'),
  apiErrorMessage: __('An error occurred while fetching. Please try again.'),
};

export default {
  name: 'ListSelector',
  i18n: I18N,
  components: {
    GlCard,
    GlIcon,
    GlSearchBoxByType,
    GlCollapsibleListbox,
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
    groupId: {
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
        (item) => !this.selectedItems.some((selectedItem) => selectedItem.id === item.id),
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
      const users = await Api.projectUsers(this.projectPath, search, this.usersQueryOptions);

      return users?.map((user) => ({
        text: user.name,
        value: user.username,
        ...this.convertToCamelCase(user),
      }));
    },
    async fetchGroupsBySearchTerm(search) {
      let groups = [];
      if (this.groupId) {
        groups = await this.fetchSubgroupsBySearchTerm(search);
        return groups;
      }
      if (parseBoolean(this.isProjectNamespace)) {
        groups = await this.fetchProjectGroups(search);
      } else {
        groups = await this.fetchAllGroups(search);
      }

      return groups;
    },
    fetchProjectGroups(search) {
      return Api.projectGroups(this.projectPath, {
        search,
        with_shared: true,
        shared_min_access_level: ACCESS_LEVEL_REPORTER_INTEGER,
      }).then((data) =>
        data?.map((group) => ({
          text: group.full_name,
          value: group.name,
          ...this.convertToCamelCase(group),
        })),
      );
    },
    fetchAllGroups(search) {
      return this.$apollo
        .query({
          query: groupsAutocompleteQuery,
          variables: { search },
        })
        .then(({ data }) =>
          data?.groups.nodes.map((group) => ({
            text: group.fullName,
            value: group.name,
            ...group,
            id: getIdFromGraphQLId(group.id),
            type: 'group',
          })),
        );
    },
    async fetchSubgroupsBySearchTerm(search) {
      let groups = [];
      const subgroups = await Api.groupSubgroups(this.groupId, search);
      groups = subgroups?.data || [];
      return groups?.map((group) => ({
        text: group.fullName,
        value: group.name,
        type: 'group',
        ...group,
      }));
    },
    fetchDeployKeysBySearchTerm() {
      // TODO - implement API request (follow-up)
      // https://gitlab.com/gitlab-org/gitlab/-/issues/432494
    },
    async fetchProjectsBySearchTerm(search) {
      const response = await getProjects(search, { membership: false });
      const projects = response?.data || [];

      return projects.map((project) => ({
        ...this.convertToCamelCase(project),
        text: project.name,
        value: project.id,
        type: 'project',
      }));
    },
    getItemByKey(key) {
      return this.items.find((item) => item[this.config.filterKey] === key);
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
  <gl-card header-class="gl-new-card-header gl-border-none" body-class="gl-card-footer">
    <template #header
      ><strong data-testid="list-selector-title"
        >{{ config.title }}
        <span class="gl-ml-3 gl-text-gray-700"
          ><gl-icon :name="config.icon" /> {{ selectedItems.length }}</span
        ></strong
      ></template
    >

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

    <div v-else class="gl-mt-5 gl-text-secondary">{{ emptyPlaceholder }}</div>
  </gl-card>
</template>
