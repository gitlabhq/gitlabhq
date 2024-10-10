<script>
import { __ } from '~/locale';
import Api from '~/api';
import searchTodosProjectsQuery from '../queries/search_todos_projects.query.graphql';
import AsyncToken from './async_token.vue';

export default {
  i18n: {
    suggestionsFetchError: __('There was a problem fetching projects.'),
  },
  components: {
    AsyncToken,
  },
  methods: {
    fetchProjects(search = '') {
      return this.$apollo
        .query({
          query: searchTodosProjectsQuery,
          variables: { search },
        })
        .then(({ data }) => data.projects.nodes);
    },
    fetchProject(projectId) {
      return Api.project(projectId).then(({ data }) => data);
    },
    displayValue(project) {
      return project?.name;
    },
  },
};
</script>

<template>
  <async-token
    :fetch-suggestions="fetchProjects"
    :suggestions-fetch-error="$options.i18n.suggestionsFetchError"
    :fetch-active-token-value="fetchProject"
    v-bind="$attrs"
    v-on="$listeners"
  >
    <template #token-value="{ inputValue, activeTokenValue }">
      {{ activeTokenValue ? displayValue(activeTokenValue) : inputValue }}
    </template>
    <template #suggestion-display-name="{ suggestion }">
      {{ suggestion.fullPath }}
    </template>
  </async-token>
</template>
