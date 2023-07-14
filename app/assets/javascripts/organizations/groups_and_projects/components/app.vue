<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { createAlert } from '~/alert';
import projectsQuery from '../graphql/queries/projects.query.graphql';

export default {
  i18n: {
    pageTitle: __('Groups and projects'),
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
        return data.organization.projects.nodes;
      },
      error(error) {
        createAlert({ message: this.$options.i18n.errorMessage, error, captureError: true });
      },
    },
  },
  computed: {
    formattedProjects() {
      return this.projects.map(({ id, nameWithNamespace, accessLevel, ...project }) => ({
        ...project,
        id: getIdFromGraphQLId(id),
        name: nameWithNamespace,
        permissions: {
          projectAccess: {
            accessLevel: accessLevel.integerValue,
          },
        },
      }));
    },
    isLoading() {
      return this.$apollo.queries.projects?.loading;
    },
  },
};
</script>

<template>
  <div>
    <h1 class="gl-font-size-h-display">{{ $options.i18n.pageTitle }}</h1>
    <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="md" />
    <projects-list v-else :projects="formattedProjects" show-project-icon />
  </div>
</template>
