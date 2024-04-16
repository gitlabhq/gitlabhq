<script>
import { GlLoadingIcon, GlEmptyState, GlKeysetPagination } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import { ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';
import { DEFAULT_PER_PAGE } from '~/api';
import { deleteProject } from '~/rest_api';
import { createAlert } from '~/alert';
import {
  renderProjectDeleteSuccessToast,
  deleteProjectParams,
  formatProjects,
} from 'ee_else_ce/organizations/shared/utils';
import { SORT_ITEM_NAME, SORT_DIRECTION_ASC } from '../constants';
import projectsQuery from '../graphql/queries/projects.query.graphql';
import NewProjectButton from './new_project_button.vue';

export default {
  i18n: {
    errorMessage: s__(
      'Organization|An error occurred loading the projects. Please refresh the page to try again.',
    ),
    deleteErrorMessage: s__(
      'Organization|An error occurred deleting the project. Please refresh the page to try again.',
    ),
    emptyState: {
      title: s__("Organization|You don't have any projects yet."),
      description: s__(
        'GroupsEmptyState|Projects are where you can store your code, access issues, wiki, and other features of GitLab.',
      ),
    },
    prev: __('Prev'),
    next: __('Next'),
  },
  components: {
    ProjectsList,
    GlLoadingIcon,
    GlEmptyState,
    GlKeysetPagination,
    NewProjectButton,
  },
  inject: {
    organizationGid: {},
    projectsEmptyStateSvgPath: {},
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
          search: this.search,
          sort: this.sort,
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
    sort() {
      return `${this.sortName}_${this.sortDirection}`;
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
    setProjectIsDeleting(nodeIndex, value) {
      this.projects.nodes[nodeIndex].actionLoadingStates[ACTION_DELETE] = value;
    },
    async deleteProject(project) {
      const nodeIndex = this.projects.nodes.findIndex((node) => node.id === project.id);

      try {
        this.setProjectIsDeleting(nodeIndex, true);
        await deleteProject(project.id, deleteProjectParams(project));
        this.$apollo.queries.projects.refetch();
        renderProjectDeleteSuccessToast(project);
      } catch (error) {
        createAlert({ message: this.$options.i18n.deleteErrorMessage, error, captureError: true });
      } finally {
        this.setProjectIsDeleting(nodeIndex, false);
      }
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="md" />
  <div v-else-if="nodes.length">
    <projects-list
      :projects="nodes"
      show-project-icon
      :list-item-class="listItemClass"
      @delete="deleteProject"
    />
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
  <gl-empty-state v-else v-bind="emptyStateProps">
    <template v-if="shouldShowEmptyStateButtons" #actions>
      <new-project-button />
    </template>
  </gl-empty-state>
</template>
