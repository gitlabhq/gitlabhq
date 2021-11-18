<script>
import {
  GlButton,
  GlButtonGroup,
  GlDropdown,
  GlDropdownItem,
  GlDropdownText,
  GlDropdownSectionHeader,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { joinPaths } from '~/lib/utils/url_utility';
import { MINIMUM_SEARCH_LENGTH } from '~/graphql_shared/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import Tracking from '~/tracking';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import searchNamespacesWhereUserCanCreateProjectsQuery from '../queries/search_namespaces_where_user_can_create_projects.query.graphql';
import eventHub from '../event_hub';

export default {
  components: {
    GlButton,
    GlButtonGroup,
    GlDropdown,
    GlDropdownItem,
    GlDropdownText,
    GlDropdownSectionHeader,
    GlSearchBoxByType,
  },
  mixins: [Tracking.mixin()],
  apollo: {
    currentUser: {
      query: searchNamespacesWhereUserCanCreateProjectsQuery,
      variables() {
        return {
          search: this.search,
        };
      },
      skip() {
        return this.search.length > 0 && this.search.length < MINIMUM_SEARCH_LENGTH;
      },
      debounce: DEBOUNCE_DELAY,
    },
  },
  inject: [
    'namespaceFullPath',
    'namespaceId',
    'rootUrl',
    'trackLabel',
    'userNamespaceFullPath',
    'userNamespaceId',
  ],
  data() {
    return {
      currentUser: {},
      groupToFilterBy: undefined,
      search: '',
      selectedNamespace: this.namespaceId
        ? {
            id: this.namespaceId,
            fullPath: this.namespaceFullPath,
          }
        : {
            id: this.userNamespaceId,
            fullPath: this.userNamespaceFullPath,
          },
    };
  },
  computed: {
    userGroups() {
      return this.currentUser.groups?.nodes || [];
    },
    userNamespace() {
      return this.currentUser.namespace || {};
    },
    filteredGroups() {
      return this.groupToFilterBy
        ? this.userGroups.filter((group) =>
            group.fullPath.startsWith(this.groupToFilterBy.fullPath),
          )
        : this.userGroups;
    },
    hasGroupMatches() {
      return this.filteredGroups.length;
    },
    hasNamespaceMatches() {
      return (
        this.userNamespace.fullPath?.toLowerCase().includes(this.search.toLowerCase()) &&
        !this.groupToFilterBy
      );
    },
    hasNoMatches() {
      return !this.hasGroupMatches && !this.hasNamespaceMatches;
    },
  },
  created() {
    eventHub.$on('select-template', this.handleSelectTemplate);
  },
  beforeDestroy() {
    eventHub.$off('select-template', this.handleSelectTemplate);
  },
  methods: {
    focusInput() {
      this.$refs.search.focusInput();
    },
    handleDropdownItemClick(namespace) {
      eventHub.$emit('update-visibility', {
        name: namespace.name,
        visibility: namespace.visibility,
        showPath: namespace.webUrl,
        editPath: joinPaths(namespace.webUrl, '-', 'edit'),
      });
      this.setNamespace(namespace);
    },
    handleSelectTemplate(groupId) {
      this.groupToFilterBy = this.userGroups.find(
        (group) => getIdFromGraphQLId(group.id) === groupId,
      );
      if (this.groupToFilterBy) {
        this.setNamespace(this.groupToFilterBy);
      }
    },
    setNamespace({ id, fullPath }) {
      this.selectedNamespace = {
        id: getIdFromGraphQLId(id),
        fullPath,
      };
    },
  },
};
</script>

<template>
  <gl-button-group class="input-lg">
    <gl-button class="gl-text-truncate" label :title="rootUrl">{{ rootUrl }}</gl-button>
    <gl-dropdown
      :text="selectedNamespace.fullPath"
      toggle-class="gl-rounded-top-right-base! gl-rounded-bottom-right-base! gl-w-20"
      data-qa-selector="select_namespace_dropdown"
      @show="track('activate_form_input', { label: trackLabel, property: 'project_path' })"
      @shown="focusInput"
    >
      <gl-search-box-by-type
        ref="search"
        v-model.trim="search"
        :is-loading="$apollo.queries.currentUser.loading"
        data-qa-selector="select_namespace_dropdown_search_field"
      />
      <template v-if="!$apollo.queries.currentUser.loading">
        <template v-if="hasGroupMatches">
          <gl-dropdown-section-header>{{ __('Groups') }}</gl-dropdown-section-header>
          <gl-dropdown-item
            v-for="group of filteredGroups"
            :key="group.id"
            @click="handleDropdownItemClick(group)"
          >
            {{ group.fullPath }}
          </gl-dropdown-item>
        </template>
        <template v-if="hasNamespaceMatches">
          <gl-dropdown-section-header>{{ __('Users') }}</gl-dropdown-section-header>
          <gl-dropdown-item @click="handleDropdownItemClick(userNamespace)">
            {{ userNamespace.fullPath }}
          </gl-dropdown-item>
        </template>
        <gl-dropdown-text v-if="hasNoMatches">{{ __('No matches found') }}</gl-dropdown-text>
      </template>
    </gl-dropdown>

    <input
      id="project_namespace_id"
      type="hidden"
      name="project[namespace_id]"
      :value="selectedNamespace.id"
    />
  </gl-button-group>
</template>
