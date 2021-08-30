<script>
import {
  GlButton,
  GlButtonGroup,
  GlDropdown,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlLoadingIcon,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { MINIMUM_SEARCH_LENGTH } from '~/graphql_shared/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import Tracking from '~/tracking';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import searchNamespacesWhereUserCanCreateProjectsQuery from '../queries/search_namespaces_where_user_can_create_projects.query.graphql';

export default {
  components: {
    GlButton,
    GlButtonGroup,
    GlDropdown,
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlLoadingIcon,
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
  inject: ['namespaceFullPath', 'namespaceId', 'rootUrl', 'trackLabel'],
  data() {
    return {
      currentUser: {},
      search: '',
      selectedNamespace: {
        id: this.namespaceId,
        fullPath: this.namespaceFullPath,
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
  },
  methods: {
    handleClick({ id, fullPath }) {
      this.selectedNamespace = {
        id: getIdFromGraphQLId(id),
        fullPath,
      };
    },
  },
};
</script>

<template>
  <gl-button-group class="gl-w-full">
    <gl-button label>{{ rootUrl }}</gl-button>
    <gl-dropdown
      class="gl-w-full"
      :text="selectedNamespace.fullPath"
      toggle-class="gl-rounded-top-right-base! gl-rounded-bottom-right-base!"
      data-qa-selector="select_namespace_dropdown"
      @show="track('activate_form_input', { label: trackLabel, property: 'project_path' })"
    >
      <gl-search-box-by-type v-model.trim="search" />
      <gl-loading-icon v-if="$apollo.queries.currentUser.loading" />
      <template v-else>
        <gl-dropdown-section-header>{{ __('Groups') }}</gl-dropdown-section-header>
        <gl-dropdown-item v-for="group of userGroups" :key="group.id" @click="handleClick(group)">
          {{ group.fullPath }}
        </gl-dropdown-item>
        <gl-dropdown-section-header>{{ __('Users') }}</gl-dropdown-section-header>
        <gl-dropdown-item @click="handleClick(userNamespace)">
          {{ userNamespace.fullPath }}
        </gl-dropdown-item>
      </template>
    </gl-dropdown>

    <input type="hidden" name="project[namespace_id]" :value="selectedNamespace.id" />
  </gl-button-group>
</template>
