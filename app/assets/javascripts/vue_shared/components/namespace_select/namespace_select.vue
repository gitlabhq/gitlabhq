<script>
import {
  GlDropdown,
  GlDropdownDivider,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { __ } from '~/locale';

export const EMPTY_NAMESPACE_ID = -1;
export const i18n = {
  DEFAULT_TEXT: __('Select a new namespace'),
  DEFAULT_EMPTY_NAMESPACE_TEXT: __('No namespace'),
  GROUPS: __('Groups'),
  USERS: __('Users'),
};

const filterByName = (data, searchTerm = '') =>
  data.filter((d) => d.humanName.toLowerCase().includes(searchTerm));

export default {
  name: 'NamespaceSelect',
  components: {
    GlDropdown,
    GlDropdownDivider,
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlSearchBoxByType,
  },
  props: {
    data: {
      type: Object,
      required: true,
    },
    fullWidth: {
      type: Boolean,
      required: false,
      default: false,
    },
    defaultText: {
      type: String,
      required: false,
      default: i18n.DEFAULT_TEXT,
    },
    includeHeaders: {
      type: Boolean,
      required: false,
      default: true,
    },
    emptyNamespaceTitle: {
      type: String,
      required: false,
      default: i18n.DEFAULT_EMPTY_NAMESPACE_TEXT,
    },
    includeEmptyNamespace: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      searchTerm: '',
      selectedNamespace: null,
    };
  },
  computed: {
    hasUserNamespaces() {
      return this.data.user?.length;
    },
    hasGroupNamespaces() {
      return this.data.group?.length;
    },
    filteredGroupNamespaces() {
      if (!this.hasGroupNamespaces) return [];
      return filterByName(this.data.group, this.searchTerm);
    },
    filteredUserNamespaces() {
      if (!this.hasUserNamespaces) return [];
      return filterByName(this.data.user, this.searchTerm);
    },
    selectedNamespaceText() {
      return this.selectedNamespace?.humanName || this.defaultText;
    },
    filteredEmptyNamespaceTitle() {
      const { includeEmptyNamespace, emptyNamespaceTitle, searchTerm } = this;
      return includeEmptyNamespace && emptyNamespaceTitle.toLowerCase().includes(searchTerm);
    },
  },
  methods: {
    handleSelect(item) {
      this.selectedNamespace = item;
      this.$emit('select', item);
    },
    handleSelectEmptyNamespace() {
      this.handleSelect({ id: EMPTY_NAMESPACE_ID, humanName: this.emptyNamespaceTitle });
    },
  },
  i18n,
};
</script>
<template>
  <gl-dropdown :text="selectedNamespaceText" :block="fullWidth" data-qa-selector="namespaces_list">
    <template #header>
      <gl-search-box-by-type v-model.trim="searchTerm" />
    </template>
    <div v-if="filteredEmptyNamespaceTitle">
      <gl-dropdown-item
        data-qa-selector="namespaces_list_item"
        @click="handleSelectEmptyNamespace()"
      >
        {{ emptyNamespaceTitle }}
      </gl-dropdown-item>
      <gl-dropdown-divider />
    </div>
    <div v-if="hasGroupNamespaces" data-qa-selector="namespaces_list_groups">
      <gl-dropdown-section-header v-if="includeHeaders">{{
        $options.i18n.GROUPS
      }}</gl-dropdown-section-header>
      <gl-dropdown-item
        v-for="item in filteredGroupNamespaces"
        :key="item.id"
        data-qa-selector="namespaces_list_item"
        @click="handleSelect(item)"
        >{{ item.humanName }}</gl-dropdown-item
      >
    </div>
    <div v-if="hasUserNamespaces" data-qa-selector="namespaces_list_users">
      <gl-dropdown-section-header v-if="includeHeaders">{{
        $options.i18n.USERS
      }}</gl-dropdown-section-header>
      <gl-dropdown-item
        v-for="item in filteredUserNamespaces"
        :key="item.id"
        data-qa-selector="namespaces_list_item"
        @click="handleSelect(item)"
        >{{ item.humanName }}</gl-dropdown-item
      >
    </div>
  </gl-dropdown>
</template>
