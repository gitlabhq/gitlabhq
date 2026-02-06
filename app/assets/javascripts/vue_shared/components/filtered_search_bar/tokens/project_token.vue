<script>
import { GlFilteredSearchSuggestion } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import projectsAutocompleteQuery from '~/graphql_shared/queries/projects_autocomplete.query.graphql';

import { createAlert } from '~/alert';
import { __ } from '~/locale';

export default {
  name: 'ProjectToken',
  separator: '::',
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
      // Avoids the flash of empty dropdown, assume loading until not.
      loading: true,
    };
  },
  computed: {
    defaultProjects() {
      return this.config.defaultProjects || [];
    },
  },

  methods: {
    async fetchProjectsBySearchTerm(search = '') {
      this.loading = true;

      try {
        const { data = {} } = await this.$apollo.query({
          query: projectsAutocompleteQuery,
          variables: { search },
        });

        this.projects = data.projects?.nodes || [];
      } catch (e) {
        createAlert({
          message: __('There was a problem fetching projects.'),
        });
        this.projects = [];
      } finally {
        this.loading = false;
      }
    },
    displayValue(project) {
      const prefix = this.config.skipIdPrefix
        ? ''
        : `${this.getProjectIdProperty(project)}${this.$options.separator}`;
      return `${prefix}${project.fullPath}`;
    },
    getProjectIdProperty(project) {
      return getIdFromGraphQLId(project.id);
    },
    getValue(project) {
      return project.fullPath;
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
    :default-suggestions="defaultProjects"
    search-by="title"
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
        :key="getValue(project)"
        :value="getValue(project)"
      >
        {{ project.fullPath }}
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
