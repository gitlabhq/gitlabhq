<script>
import { GlButton, GlTruncate, GlCollapsibleListbox, GlIcon } from '@gitlab/ui';
import { PATH_SEPARATOR } from '~/lib/utils/url_utility';
import { MINIMUM_SEARCH_LENGTH } from '~/graphql_shared/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import Tracking from '~/tracking';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import { __, s__, n__ } from '~/locale';
import searchNamespacesWhereUserCanCreateProjectsQuery from '~/projects/new/queries/search_namespaces_where_user_can_create_projects.query.graphql';

export default {
  components: {
    GlButton,
    GlTruncate,
    GlCollapsibleListbox,
    GlIcon,
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
  inject: ['userNamespaceId', 'canCreateProject'],
  props: {
    namespaceFullPath: {
      type: String,
      required: false,
      default: '',
    },
    namespaceId: {
      type: String,
      required: false,
      default: '',
    },
    trackLabel: {
      type: String,
      required: false,
      default: '',
    },
    groupsOnly: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
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
      userNamespaceUniqueId: this.userNamespaceId,
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
    items() {
      if (this.groupsOnly) return this.groupsItems;
      if (this.canCreateProject) return this.namespaceItems.concat(this.groupsItems);
      return this.groupsItems;
    },
    groupsItems() {
      if (this.hasGroupMatches) {
        return [
          {
            text: __('Groups'),
            options: this.filteredGroups.map((group) => ({
              value: group.id,
              text: group.fullPath,
            })),
          },
        ];
      }

      return [];
    },
    allItems() {
      return this.filteredGroups.concat(this.currentUser.namespace);
    },
    namespaceItems() {
      if (this.hasNamespaceMatches && this.userNamespaceUniqueId)
        return [
          {
            text: __('Personal namespaces'),
            options: [
              {
                value: this.userNamespace.id,
                text: this.userNamespace.fullPath,
              },
            ],
          },
        ];
      return [];
    },
    dropdownPlaceholderClass() {
      return this.selectedNamespace.id ? '' : '!gl-text-subtle';
    },
    dropdownText() {
      if (this.selectedNamespace && this.selectedNamespace?.fullPath) {
        return this.selectedNamespace.fullPath;
      }
      return null;
    },
    loading() {
      return this.$apollo.queries.currentUser.loading;
    },
    searchSummary() {
      return n__(
        'ProjectsNew|%d group or namespace found',
        'ProjectsNew|%d groups or namespaces found',
        this.items.length,
      );
    },
  },
  methods: {
    handleDropdownShown() {
      if (this.shouldSkipQuery) {
        this.shouldSkipQuery = false;
      }
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
    onSearch(query) {
      this.search = query;
    },
  },
  i18n: {
    emptySearchResult: __('No matches found'),
  },
  emptyNameSpace: {
    id: undefined,
    fullPath: s__('ProjectsNew|Pick a group or namespace'),
  },
};
</script>

<template>
  <gl-collapsible-listbox
    searchable
    fluid-width
    :searching="loading"
    :items="items"
    :toggle-text="dropdownText"
    :no-results-text="$options.i18n.emptySearchResult"
    class="gl-w-full"
    @show="trackDropdownShow"
    @shown="handleDropdownShown"
    @search="onSearch"
  >
    <template #toggle>
      <gl-button :class="dropdownPlaceholderClass">
        <gl-truncate
          :text="dropdownText"
          position="start"
          class="gl-mr-auto gl-overflow-hidden"
          with-tooltip
        />
        <gl-icon class="gl-button-icon dropdown-chevron !gl-ml-2 !gl-mr-0" name="chevron-down" />
      </gl-button>
    </template>
    <template #search-summary-sr-only>
      {{ searchSummary }}
    </template>
  </gl-collapsible-listbox>
</template>
