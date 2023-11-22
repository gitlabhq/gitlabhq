<script>
import { GlCard, GlIcon, GlCollapsibleListbox, GlSearchBoxByType } from '@gitlab/ui';
import { parseBoolean } from '~/lib/utils/common_utils';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import groupsAutocompleteQuery from '~/graphql_shared/queries/groups_autocomplete.query.graphql';
import Api from '~/api';
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
  },
  data() {
    return {
      searchValue: '',
      isProjectNamespace: 'true',
      selected: [],
      items: [],
    };
  },
  computed: {
    config() {
      return CONFIG[this.type];
    },
    namespaceDropdownText() {
      return parseBoolean(this.isProjectNamespace)
        ? this.$options.i18n.projectGroups
        : this.$options.i18n.allGroups;
    },
  },
  methods: {
    async handleSearchInput(search) {
      this.$refs.results.open();

      const searchMethod = {
        users: this.fetchUsersBySearchTerm,
        groups: this.fetchGroupsBySearchTerm,
        deployKeys: this.fetchDeployKeysBySearchTerm,
      };

      try {
        this.items = await searchMethod[this.type](search);
      } catch (e) {
        createAlert({
          message: this.$options.i18n.apiErrorMessage,
        });
      }
    },
    async fetchUsersBySearchTerm(search) {
      let users = [];
      if (parseBoolean(this.isProjectNamespace)) {
        users = await Api.projectUsers(this.projectPath, search);
      } else {
        const groupMembers = await Api.groupMembers(this.groupPath, { query: search });
        users = groupMembers?.data || [];
      }

      return users?.map((user) => ({ text: user.name, value: user.username, ...user }));
    },
    fetchGroupsBySearchTerm(search) {
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
          })),
        );
    },
    fetchDeployKeysBySearchTerm() {
      // TODO - implement API request (follow-up)
      // https://gitlab.com/gitlab-org/gitlab/-/issues/432494
    },
    getItemByKey(key) {
      return this.items.find((item) => item[this.config.filterKey] === key);
    },
    handleSelectItem(key) {
      this.$emit('select', this.getItemByKey(key));
    },
    handleDeleteItem(key) {
      this.$emit('delete', key);
    },
    handleSelectNamespace() {
      this.items = [];
      this.searchValue = '';
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
        <span class="gl-text-gray-700 gl-ml-3"
          ><gl-icon :name="config.icon" /> {{ selectedItems.length }}</span
        ></strong
      ></template
    >

    <div class="gl-display-flex gl-gap-3" :class="{ 'gl-mb-4': selectedItems.length }">
      <gl-collapsible-listbox
        ref="results"
        v-model="selected"
        class="list-selector gl-display-block gl-flex-grow-1"
        :items="items"
        multiple
        @shown="$refs.search.focusInput()"
      >
        <template #toggle>
          <gl-search-box-by-type
            ref="search"
            v-model="searchValue"
            autofocus
            debounce="500"
            @input="handleSearchInput"
          />
        </template>

        <template #list-item="{ item }">
          <component :is="config.component" :data="item" @select="handleSelectItem" />
        </template>
      </gl-collapsible-listbox>

      <gl-collapsible-listbox
        v-if="config.showNamespaceDropdown"
        v-model="isProjectNamespace"
        :toggle-text="namespaceDropdownText"
        :items="$options.namespaceOptions"
        @select="handleSelectNamespace"
      />
    </div>

    <component
      :is="config.component"
      v-for="(item, index) of selectedItems"
      :key="index"
      :class="{ 'gl-border-t': index > 0 }"
      class="gl-p-3"
      :data="item"
      can-delete
      @delete="handleDeleteItem"
    />
  </gl-card>
</template>
