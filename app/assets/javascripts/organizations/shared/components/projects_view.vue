<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import { createAlert } from '~/alert';
import projectsQuery from '../graphql/queries/projects.query.graphql';
import { formatProjects } from '../utils';

export default {
  i18n: {
    errorMessage: s__(
      'Organization|An error occurred loading the projects. Please refresh the page to try again.',
    ),
  },
  components: {
    ProjectsList,
    GlLoadingIcon,
  },
  data() {
    return {
      projects: [],
    };
  },
  apollo: {
    projects: {
      query: projectsQuery,
      update(data) {
        return formatProjects(data.organization.projects.nodes);
      },
      error(error) {
        createAlert({ message: this.$options.i18n.errorMessage, error, captureError: true });
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.projects.loading;
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="md" />
  <projects-list v-else :projects="projects" show-project-icon />
</template>
