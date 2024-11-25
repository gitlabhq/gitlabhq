<script>
import { GlButton, GlButtonGroup, GlTruncate, GlCollapsibleListbox, GlIcon } from '@gitlab/ui';
import { joinPaths, PATH_SEPARATOR } from '~/lib/utils/url_utility';
import { MINIMUM_SEARCH_LENGTH } from '~/graphql_shared/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import Tracking from '~/tracking';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import { __, s__, n__ } from '~/locale';
import searchNamespacesWhereUserCanCreateProjectsQuery from '../queries/search_namespaces_where_user_can_create_projects.query.graphql';
import eventHub from '../event_hub';

export default {
  components: {
    GlButton,
    GlButtonGroup,
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
      return this.groupsItems.concat(this.namespaceItems);
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
            text: __('Users'),
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
    },
    handleDropdownItemClick(namespaceId) {
      const namespace = this.allItems.find((item) => item.id === namespaceId);

      if (namespace) {
        eventHub.$emit('update-visibility', {
          name: namespace.name,
          visibility: namespace.visibility,
          showPath: namespace.webUrl,
          editPath: joinPaths(namespace.webUrl, '-', 'edit'),
        });
      }
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
  <gl-button-group class="gl-w-full">
    <gl-button class="js-group-namespace-button !gl-grow-0 gl-truncate" label :title="rootUrl">{{
      rootUrl
    }}</gl-button>

    <gl-collapsible-listbox
      searchable
      fluid-width
      :searching="loading"
      :items="items"
      class="js-group-namespace-dropdown group-namespace-dropdown gl-grow"
      :toggle-text="dropdownText"
      :no-results-text="$options.i18n.emptySearchResult"
      data-testid="select-namespace-dropdown"
      @show="trackDropdownShow"
      @shown="handleDropdownShown"
      @select="handleDropdownItemClick"
      @search="onSearch"
    >
      <template #toggle>
        <gl-button
          class="gl-w-20 !gl-basis-full !gl-rounded-l-none"
          :class="dropdownPlaceholderClass"
        >
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
    <input type="hidden" name="project[selected_namespace_id]" :value="selectedNamespace.id" />

    <input
      :id="inputId"
      type="hidden"
      :name="inputName"
      :value="selectedNamespace.id || userNamespaceUniqueId"
    />
  </gl-button-group>
</template>
