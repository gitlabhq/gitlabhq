<script>
import { GlLoadingIcon, GlEmptyState, GlKeysetPagination } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import { DEFAULT_PER_PAGE } from '~/api';
import { createAlert } from '~/alert';
import { SORT_ITEM_NAME, SORT_DIRECTION_ASC } from '../constants';
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
        'GroupsEmptyState|Projects are where you can store your code, access issues, wiki, and other features of GitLab.',
      ),
      primaryButtonText: __('New project'),
    },
    prev: __('Prev'),
    next: __('Next'),
  },
  components: {
    ProjectsList,
    GlLoadingIcon,
    GlEmptyState,
    GlKeysetPagination,
  },
  inject: {
    organizationGid: {},
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
    listItemClass: {
      type: [String, Array, Object],
      required: false,
      default: '',
    },
    startCursor: {
      type: String,
      required: false,
      default: null,
    },
    endCursor: {
      type: String,
      required: false,
      default: null,
    },
    perPage: {
      type: Number,
      required: false,
      default: DEFAULT_PER_PAGE,
    },
    search: {
      type: String,
      required: false,
      default: '',
    },
    sortName: {
      type: String,
      required: false,
      default: SORT_ITEM_NAME.value,
    },
    sortDirection: {
      type: String,
      required: false,
      default: SORT_DIRECTION_ASC,
    },
  },
  data() {
    return {
      projects: {},
    };
  },
  apollo: {
    projects: {
      query: projectsQuery,
      variables() {
        return {
          id: this.organizationGid,
          ...this.pagination,
        };
      },
      update({
        organization: {
          projects: { nodes, pageInfo },
        },
      }) {
        return {
          nodes: formatProjects(nodes),
          pageInfo,
        };
      },
      result() {
        this.$emit('page-change', {
          endCursor: this.pagination.after,
          startCursor: this.pagination.before,
          hasPreviousPage: this.pageInfo.hasPreviousPage,
        });
      },
      error(error) {
        createAlert({ message: this.$options.i18n.errorMessage, error, captureError: true });
      },
    },
  },
  computed: {
    nodes() {
      return this.projects.nodes || [];
    },
    pageInfo() {
      return this.projects.pageInfo || {};
    },
    pagination() {
      if (!this.startCursor && !this.endCursor) {
        return {
          first: this.perPage,
          after: null,
          last: null,
          before: null,
        };
      }

      return {
        first: this.endCursor && this.perPage,
        after: this.endCursor,
        last: this.startCursor && this.perPage,
        before: this.startCursor,
      };
    },
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
  methods: {
    onNext(endCursor) {
      this.$emit('page-change', {
        endCursor,
        startCursor: null,
      });
    },
    onPrev(startCursor) {
      this.$emit('page-change', {
        endCursor: null,
        startCursor,
      });
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="md" />
  <div v-else-if="nodes.length">
    <projects-list :projects="nodes" show-project-icon :list-item-class="listItemClass" />
    <div v-if="pageInfo.hasNextPage || pageInfo.hasPreviousPage" class="gl-text-center gl-mt-5">
      <gl-keyset-pagination
        v-bind="pageInfo"
        :prev-text="$options.i18n.prev"
        :next-text="$options.i18n.next"
        @prev="onPrev"
        @next="onNext"
      />
    </div>
  </div>
  <gl-empty-state v-else v-bind="emptyStateProps" />
</template>
