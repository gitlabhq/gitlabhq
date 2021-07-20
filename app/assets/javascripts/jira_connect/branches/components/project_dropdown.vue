<script>
import { GlDropdown, GlDropdownItem, GlSearchBoxByType, GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import { PROJECTS_PER_PAGE } from '../constants';
import getProjectsQuery from '../graphql/queries/get_projects.query.graphql';

export default {
  PROJECTS_PER_PAGE,
  projectQueryPageInfo: {
    endCursor: '',
  },
  components: {
    GlDropdown,
    GlDropdownItem,
    GlSearchBoxByType,
    GlLoadingIcon,
  },
  props: {
    selectedProject: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      initialProjectsLoading: true,
      projectSearchQuery: '',
    };
  },
  apollo: {
    projects: {
      query: getProjectsQuery,
      variables() {
        return {
          search: this.projectSearchQuery,
          first: this.$options.PROJECTS_PER_PAGE,
          after: this.$options.projectQueryPageInfo.endCursor,
          searchNamespaces: true,
          sort: 'similarity',
        };
      },
      update(data) {
        return data?.projects?.nodes.filter((project) => !project.repository.empty) ?? [];
      },
      result() {
        this.initialProjectsLoading = false;
      },
      error() {
        this.onError({ message: __('Failed to load projects') });
      },
    },
  },
  computed: {
    projectsLoading() {
      return Boolean(this.$apollo.queries.projects.loading);
    },
    projectDropdownText() {
      return this.selectedProject?.nameWithNamespace || __('Select a project');
    },
  },
  methods: {
    async onProjectSelect(project) {
      this.$emit('change', project);
    },
    onError({ message } = {}) {
      this.$emit('error', { message });
    },
    isProjectSelected(project) {
      return project.id === this.selectedProject?.id;
    },
  },
};
</script>

<template>
  <gl-dropdown :text="projectDropdownText" :loading="initialProjectsLoading">
    <template #header>
      <gl-search-box-by-type v-model.trim="projectSearchQuery" :debounce="250" />
    </template>

    <gl-loading-icon v-show="projectsLoading" />
    <template v-if="!projectsLoading">
      <gl-dropdown-item
        v-for="project in projects"
        :key="project.id"
        is-check-item
        :is-checked="isProjectSelected(project)"
        @click="onProjectSelect(project)"
      >
        {{ project.nameWithNamespace }}
      </gl-dropdown-item>
    </template>
  </gl-dropdown>
</template>
