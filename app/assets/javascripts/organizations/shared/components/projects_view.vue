<script>
import { GlLoadingIcon, GlKeysetPagination } from '@gitlab/ui';
import projectsEmptyStateSvgPath from '@gitlab/svgs/dist/illustrations/empty-state/empty-projects-md.svg?url';
import { s__ } from '~/locale';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import { DEFAULT_PER_PAGE } from '~/api';
import { createAlert } from '~/alert';
import { timestampType, formatProjects } from '~/organizations/shared/utils';
import { SORT_ITEM_NAME, SORT_DIRECTION_ASC } from '../constants';
import projectsQuery from '../graphql/queries/projects.query.graphql';
import NewProjectButton from './new_project_button.vue';
import GroupsAndProjectsEmptyState from './groups_and_projects_empty_state.vue';

export default {
  projectsEmptyStateSvgPath,
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
  },
  components: {
    ProjectsList,
    GlLoadingIcon,
    GlKeysetPagination,
    NewProjectButton,
    GroupsAndProjectsEmptyState,
  },
  inject: {
    organizationGid: {},
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
    timestampType() {
      return timestampType(this.sortName);
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
    onRefetch() {
      this.$apollo.queries.projects.refetch();
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
      :timestamp-type="timestampType"
      @refetch="onRefetch"
    />
    <div v-if="pageInfo.hasNextPage || pageInfo.hasPreviousPage" class="gl-mt-5 gl-text-center">
      <gl-keyset-pagination v-bind="pageInfo" @prev="onPrev" @next="onNext" />
    </div>
  </div>
  <groups-and-projects-empty-state
    v-else
    :svg-path="$options.projectsEmptyStateSvgPath"
    :title="$options.i18n.emptyState.title"
    :description="$options.i18n.emptyState.description"
    :search="search"
  >
    <template v-if="shouldShowEmptyStateButtons" #actions>
      <new-project-button />
    </template>
  </groups-and-projects-empty-state>
</template>
