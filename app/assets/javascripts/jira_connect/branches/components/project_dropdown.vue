<script>
import { GlAvatarLabeled, GlCollapsibleListbox } from '@gitlab/ui';
import { debounce } from 'lodash';
import { __ } from '~/locale';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { PROJECTS_PER_PAGE } from '../constants';
import getProjectsQuery from '../graphql/queries/get_projects.query.graphql';

export default {
  PROJECTS_PER_PAGE,
  projectQueryPageInfo: {
    endCursor: '',
  },
  components: {
    GlAvatarLabeled,
    GlCollapsibleListbox,
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
      selectedProjectId: this.selectedProject?.id,
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
    projectList() {
      return (this.projects || []).map((project) => ({
        ...project,
        text: project.nameWithNamespace,
        value: String(project.id),
      }));
    },
  },
  methods: {
    findProjectById(id) {
      return this.projects.find((project) => id === project.id);
    },
    onProjectSelect(projectId) {
      this.$emit('change', this.findProjectById(projectId));
    },
    onError({ message } = {}) {
      this.$emit('error', { message });
    },
    onSearch: debounce(function debouncedSearch(query) {
      this.projectSearchQuery = query;
    }, 250),
  },
  i18n: {
    selectProjectText: __('Select a project'),
  },
  AVATAR_SHAPE_OPTION_RECT,
};
</script>

<template>
  <gl-collapsible-listbox
    v-model="selectedProjectId"
    data-testid="project-select"
    :items="projectList"
    :toggle-text="projectDropdownText"
    :header-text="$options.i18n.selectProjectText"
    :loading="initialProjectsLoading"
    :searchable="true"
    :searching="projectsLoading"
    @search="onSearch"
    @select="onProjectSelect"
  >
    <template #list-item="{ item: project }">
      <gl-avatar-labeled
        v-if="project"
        class="gl-text-truncate"
        :shape="$options.AVATAR_SHAPE_OPTION_RECT"
        :size="32"
        :src="project.avatarUrl"
        :label="project.name"
        :entity-name="project.name"
        :sub-label="project.nameWithNamespace"
      />
    </template>
  </gl-collapsible-listbox>
</template>
