<script>
import { uniqBy } from 'lodash-es';
import { createAlert } from '~/alert';
import { MINIMUM_SEARCH_LENGTH, TYPENAME_USER } from '~/graphql_shared/constants';
import { s__ } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import GranularNamespaceSelector from '~/vue_shared/access_tokens/components/granular_namespace_selector.vue';
import getUserGroupsAndProjects from '~/personal_access_tokens/graphql/get_user_groups_and_projects.query.graphql';

export default {
  name: 'PersonalAccessTokenNamespaceSelector',
  components: {
    GranularNamespaceSelector,
  },
  props: {
    value: {
      type: Array,
      required: false,
      default: () => [],
    },
    error: {
      type: String,
      required: false,
      default: '',
    },
  },
  emits: ['input'],
  apollo: {
    groupsAndProjects: {
      query: getUserGroupsAndProjects,
      variables() {
        const fullPath = this.searchTerm.trim();

        return {
          id: convertToGraphQLId(TYPENAME_USER, gon.current_user_id),
          search: this.searchTerm,
          fullPath,
          hasSearch: fullPath.length > 0,
        };
      },
      skip() {
        const { length } = this.searchTerm;
        return length > 0 && length < MINIMUM_SEARCH_LENGTH;
      },
      update(data) {
        // The exact-path lookup reaches namespaces the membership-scoped search cannot,
        // and returns one the search already found when the user is a member, so it leads
        // the list and is de-duplicated against it.
        return {
          projects: uniqBy(
            [data?.projectByFullPath, ...(data?.projects?.nodes || [])].filter(Boolean),
            'id',
          ),
          groups: uniqBy(
            [data?.groupByFullPath, ...(data?.user?.groups?.nodes || [])].filter(Boolean),
            'id',
          ),
        };
      },
      error(error) {
        createAlert({
          message: this.$options.i18n.fetchError,
          captureError: true,
          error,
        });
      },
      debounce: DEBOUNCE_DELAY,
    },
  },
  data() {
    return {
      groupsAndProjects: { groups: [], projects: [] },
      searchTerm: '',
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.groupsAndProjects.loading;
    },
  },
  i18n: {
    fullPathHint: s__(
      "AccessTokens|Enter a full path to find groups or projects you're not a member of.",
    ),
    fetchError: s__('AccessTokens|Error loading groups and projects. Please refresh page.'),
  },
};
</script>

<template>
  <granular-namespace-selector
    :value="value"
    :groups="groupsAndProjects.groups"
    :projects="groupsAndProjects.projects"
    :is-loading="isLoading"
    :error="error"
    :search-hint="$options.i18n.fullPathHint"
    @input="$emit('input', $event)"
    @search="searchTerm = $event"
  />
</template>
