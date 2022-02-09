<script>
import {
  GlDropdown,
  GlSearchBoxByType,
  GlLoadingIcon,
  GlDropdownItem,
  GlAvatarLabeled,
} from '@gitlab/ui';
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
    GlAvatarLabeled,
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
        return data?.projects?.nodes.filter((project) => !project.repository?.empty) ?? [];
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
      return this.selectedProject?.nameWithNamespace || this.$options.i18n.selectProjectText;
    },
  },
  methods: {
    onProjectSelect(project) {
      this.$emit('change', project);
    },
    onError({ message } = {}) {
      this.$emit('error', { message });
    },
    isProjectSelected(project) {
      return project.id === this.selectedProject?.id;
    },
  },
  i18n: {
    selectProjectText: __('Select a project'),
  },
};
</script>

<template>
  <gl-dropdown
    :text="projectDropdownText"
    :loading="initialProjectsLoading"
    menu-class="gl-w-auto!"
    :header-text="$options.i18n.selectProjectText"
  >
    <template #header>
      <gl-search-box-by-type v-model.trim="projectSearchQuery" :debounce="250" />
    </template>

    <gl-loading-icon v-show="projectsLoading" />
    <template v-if="!projectsLoading">
      <gl-dropdown-item
        v-for="project in projects"
        :key="project.id"
        is-check-item
        is-check-centered
        :is-checked="isProjectSelected(project)"
        :data-testid="`test-project-${project.id}`"
        @click="onProjectSelect(project)"
      >
        <gl-avatar-labeled
          class="gl-text-truncate"
          shape="rect"
          :size="32"
          :src="project.avatarUrl"
          :label="project.name"
          :entity-name="project.name"
          :sub-label="project.nameWithNamespace"
        />
      </gl-dropdown-item>
    </template>
  </gl-dropdown>
</template>
