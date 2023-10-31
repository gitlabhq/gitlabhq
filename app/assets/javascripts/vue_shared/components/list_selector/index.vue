<script>
import { GlCard, GlIcon, GlCollapsibleListbox, GlSearchBoxByType } from '@gitlab/ui';
import usersAutocompleteQuery from '~/graphql_shared/queries/users_autocomplete.query.graphql';
import User from './user.vue';
import { CONFIG } from './constants';

export default {
  name: 'ListSelector',
  components: {
    GlCard,
    GlIcon,
    GlSearchBoxByType,
    GlCollapsibleListbox,
    User,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
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
  },
  data() {
    return {
      searchValue: '',
      isProject: true, // TODO: implement a way to distinguish between project/group
      selected: [],
      items: [],
    };
  },
  computed: {
    config() {
      return CONFIG[this.type];
    },
    searchItems() {
      return (
        this.items?.map((item) => ({
          value: item.username,
          text: item.name,
          ...item,
        })) || []
      );
    },
    component() {
      // Note, we can extend this for the component to support other contexts
      // https://gitlab.com/gitlab-org/gitlab/-/issues/428865
      return User;
    },
  },
  methods: {
    async handleSearchInput(search) {
      this.$refs.results.open();
      this.items = await this.fetchUsersBySearchTerm(search);
    },
    fetchUsersBySearchTerm(search) {
      const namespace = this.isProject ? 'project' : 'group';
      return this.$apollo
        .query({
          query: usersAutocompleteQuery,
          variables: { fullPath: this.projectPath, search, isProject: this.isProject },
        })
        .then(({ data }) => data[namespace]?.autocompleteUsers);
    },
    getItemByKey(key) {
      return this.searchItems.find((item) => item[this.config.filterKey] === key);
    },
    handleSelectItem(key) {
      this.$emit('select', this.getItemByKey(key));
    },
    handleDeleteItem(key) {
      this.$emit('delete', key);
    },
  },
};
</script>

<template>
  <gl-card header-class="gl-new-card-header gl-border-none" body-class="gl-card-footer">
    <template #header
      ><strong
        >{{ title }}
        <span class="gl-text-gray-500"
          ><gl-icon :name="config.icon" /> {{ selectedItems.length }}</span
        ></strong
      ></template
    >

    <gl-collapsible-listbox
      ref="results"
      v-model="selected"
      class="list-selector gl-mb-4 gl-display-block"
      :items="searchItems"
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
        <component :is="component" :data="item" @select="handleSelectItem" />
      </template>
    </gl-collapsible-listbox>

    <component
      :is="component"
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
