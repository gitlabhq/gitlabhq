<script>
import { GlFilteredSearchSuggestion } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __ } from '~/locale';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import searchTodosProjectsQuery from '../queries/search_todos_projects.query.graphql';

export default {
  components: {
    BaseToken,
    GlFilteredSearchSuggestion,
  },
  props: {
    config: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
    active: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      projects: this.config.initialProjects || [],
      loading: false,
    };
  },
  computed: {
    defaultProjects() {
      return this.config.defaultProjects || [];
    },
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
    fetchProjectsBySearchTerm(search) {
      this.loading = true;
      this.fetchProjects(search)
        .then((response) => {
          this.projects = response;
        })
        .catch(() => createAlert({ message: __('There was a problem fetching projects.') }))
        .finally(() => {
          this.loading = false;
        });
    },
    getActiveProject(projects, data) {
      if (data && projects.length) {
        return projects.find((project) => this.getValue(project) === data);
      }
      return undefined;
    },
    getValue(project) {
      return String(this.getProjectIdProperty(project));
    },
    displayValue(project) {
      return project?.name;
    },
    getProjectIdProperty(project) {
      return getIdFromGraphQLId(project.id);
    },
  },
};
</script>

<template>
  <base-token
    :config="config"
    :value="value"
    :active="active"
    :suggestions-loading="loading"
    :suggestions="projects"
    :get-active-token-value="getActiveProject"
    :default-suggestions="defaultProjects"
    :value-identifier="getValue"
    v-bind="$attrs"
    @fetch-suggestions="fetchProjectsBySearchTerm"
    v-on="$listeners"
  >
    <template #view="{ viewTokenProps: { inputValue, activeTokenValue } }">
      {{ activeTokenValue ? displayValue(activeTokenValue) : inputValue }}
    </template>
    <template #suggestions-list="{ suggestions }">
      <gl-filtered-search-suggestion
        v-for="project in suggestions"
        :key="project.id"
        :value="getValue(project)"
      >
        {{ project.fullPath }}
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
