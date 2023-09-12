<script>
import { GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import { createAlert } from '~/alert';
import projectsQuery from '../graphql/queries/projects.query.graphql';
import { formatProjects } from '../utils';

export default {
  i18n: {
    errorMessage: s__(
      'Organization|An error occurred loading the projects. Please refresh the page to try again.',
    ),
    emptyState: {
      title: s__("Organization|You don't have any projects yet."),
      description: s__(
        'GroupsEmptyState|Projects are where you can store your code, access issues, wiki, and other features of Gitlab.',
      ),
      primaryButtonText: __('New project'),
    },
  },
  components: {
    ProjectsList,
    GlLoadingIcon,
    GlEmptyState,
  },
  inject: {
    projectsEmptyStateSvgPath: {},
    newProjectPath: {
      default: null,
    },
  },
  props: {
    shouldShowEmptyStateButtons: {
      type: Boolean,
      required: false,
      default: false,
    },
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
    emptyStateProps() {
      const baseProps = {
        svgHeight: 144,
        svgPath: this.projectsEmptyStateSvgPath,
        title: this.$options.i18n.emptyState.title,
        description: this.$options.i18n.emptyState.description,
      };

      if (this.shouldShowEmptyStateButtons && this.newProjectPath) {
        return {
          ...baseProps,
          primaryButtonLink: this.newProjectPath,
          primaryButtonText: this.$options.i18n.emptyState.primaryButtonText,
        };
      }

      return baseProps;
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="md" />
  <projects-list v-else-if="projects.length" :projects="projects" show-project-icon />
  <gl-empty-state v-else v-bind="emptyStateProps" />
</template>
