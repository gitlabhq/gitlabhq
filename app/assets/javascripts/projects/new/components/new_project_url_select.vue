<script>
import {
  GlButton,
  GlButtonGroup,
  GlDropdown,
  GlDropdownItem,
  GlDropdownText,
  GlDropdownSectionHeader,
  GlSearchBoxByType,
  GlTruncate,
} from '@gitlab/ui';
import { joinPaths, PATH_SEPARATOR } from '~/lib/utils/url_utility';
import { MINIMUM_SEARCH_LENGTH } from '~/graphql_shared/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import Tracking from '~/tracking';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import { s__ } from '~/locale';
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
    GlTruncate,
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
        const hasNotEnoughSearchCharacters =
          this.search.length > 0 && this.search.length < MINIMUM_SEARCH_LENGTH;
        return this.shouldSkipQuery || hasNotEnoughSearchCharacters;
      },
      debounce: DEBOUNCE_DELAY,
    },
  },
  inject: [
    'namespaceFullPath',
    'namespaceId',
    'rootUrl',
    'trackLabel',
    'userNamespaceId',
    'inputName',
    'inputId',
  ],
  data() {
    return {
      currentUser: {},
      groupPathToFilterBy: undefined,
      search: '',
      selectedNamespace: this.namespaceId
        ? {
            id: this.namespaceId,
            fullPath: this.namespaceFullPath,
          }
        : this.$options.emptyNameSpace,
      shouldSkipQuery: true,
      userNamespaceId: this.userNamespaceId,
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
      return this.groupPathToFilterBy
        ? this.userGroups.filter((group) => group.fullPath.startsWith(this.groupPathToFilterBy))
        : this.userGroups;
    },
    hasGroupMatches() {
      return this.filteredGroups.length;
    },
    hasNamespaceMatches() {
      return (
        this.userNamespace.fullPath?.toLowerCase().includes(this.search.toLowerCase()) &&
        !this.groupPathToFilterBy
      );
    },
    hasNoMatches() {
      return !this.hasGroupMatches && !this.hasNamespaceMatches;
    },
    dropdownPlaceholderClass() {
      return this.selectedNamespace.id ? '' : 'gl-text-gray-500!';
    },
  },
  created() {
    eventHub.$on('select-template', this.handleSelectTemplate);
  },
  beforeDestroy() {
    eventHub.$off('select-template', this.handleSelectTemplate);
  },
  methods: {
    handleDropdownShown() {
      if (this.shouldSkipQuery) {
        this.shouldSkipQuery = false;
      }
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
    handleSelectTemplate(id, fullPath) {
      this.groupPathToFilterBy = fullPath.split(PATH_SEPARATOR).shift();
      this.setNamespace({ id, fullPath });
    },
    setNamespace({ id, fullPath }) {
      this.selectedNamespace = id
        ? {
            id: getIdFromGraphQLId(id),
            fullPath,
          }
        : this.$options.emptyNameSpace;
    },
    trackDropdownShow() {
      if (this.trackLabel) {
        this.track('activate_form_input', { label: this.trackLabel, property: 'project_path' });
      }
    },
  },
  emptyNameSpace: {
    id: undefined,
    fullPath: s__('ProjectsNew|Pick a group or namespace'),
  },
};
</script>

<template>
  <gl-button-group class="gl-w-full">
    <gl-button
      class="js-group-namespace-button gl-text-truncate gl-flex-grow-0!"
      label
      :title="rootUrl"
      >{{ rootUrl }}</gl-button
    >

    <gl-dropdown
      class="js-group-namespace-dropdown gl-flex-grow-1"
      :toggle-class="`gl-rounded-top-right-base! gl-rounded-bottom-right-base! gl-w-20 ${dropdownPlaceholderClass}`"
      data-qa-selector="select_namespace_dropdown"
      @show="trackDropdownShow"
      @shown="handleDropdownShown"
    >
      <template #button-text>
        <gl-truncate
          v-if="selectedNamespace.fullPath"
          :text="selectedNamespace.fullPath"
          position="start"
          with-tooltip
        />
      </template>
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
        <template v-if="hasNamespaceMatches && userNamespaceId">
          <gl-dropdown-section-header>{{ __('Users') }}</gl-dropdown-section-header>
          <gl-dropdown-item @click="handleDropdownItemClick(userNamespace)">
            {{ userNamespace.fullPath }}
          </gl-dropdown-item>
        </template>
        <gl-dropdown-text v-if="hasNoMatches">{{ __('No matches found') }}</gl-dropdown-text>
      </template>
    </gl-dropdown>

    <input type="hidden" name="project[selected_namespace_id]" :value="selectedNamespace.id" />

    <input
      :id="inputId"
      type="hidden"
      :name="inputName"
      :value="selectedNamespace.id || userNamespaceId"
    />
  </gl-button-group>
</template>
