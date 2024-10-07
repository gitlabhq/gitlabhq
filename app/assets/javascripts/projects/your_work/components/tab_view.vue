<script>
import { GlLoadingIcon, GlKeysetPagination } from '@gitlab/ui';
import { get } from 'lodash';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import { DEFAULT_PER_PAGE } from '~/api';
import { __ } from '~/locale';
import { createAlert } from '~/alert';
import { formatGraphQLProjects } from '~/vue_shared/components/projects_list/utils';
import { TIMESTAMP_TYPE_UPDATED_AT } from '~/vue_shared/components/resource_lists/constants';

export default {
  name: 'YourWorkProjectsTabView',
  TIMESTAMP_TYPE_UPDATED_AT,
  i18n: {
    errorMessage: __(
      'An error occurred loading the projects. Please refresh the page to try again.',
    ),
  },
  components: {
    GlLoadingIcon,
    GlKeysetPagination,
    ProjectsList,
  },
  props: {
    tab: {
      required: true,
      type: Object,
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
  },
  data() {
    return {
      projects: {},
    };
  },
  apollo: {
    projects() {
      return {
        query: this.tab.query,
        variables() {
          return { ...this.pagination, ...this.tab.variables };
        },
        update(response) {
          const { nodes, pageInfo } = get(response, this.tab.queryPath);

          return {
            nodes: formatGraphQLProjects(nodes),
            pageInfo,
          };
        },
        error(error) {
          createAlert({ message: this.$options.i18n.errorMessage, error, captureError: true });
        },
      };
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
          first: DEFAULT_PER_PAGE,
          after: null,
          last: null,
          before: null,
        };
      }

      return {
        first: this.endCursor && DEFAULT_PER_PAGE,
        after: this.endCursor,
        last: this.startCursor && DEFAULT_PER_PAGE,
        before: this.startCursor,
      };
    },
    isLoading() {
      return this.$apollo.queries.projects.loading;
    },
  },
  methods: {
    onDeleteComplete() {
      this.$apollo.queries.projects.refetch();
    },
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
    <projects-list
      :projects="nodes"
      show-project-icon
      list-item-class="gl-px-5"
      :timestamp-type="$options.TIMESTAMP_TYPE_UPDATED_AT"
      @delete-complete="onDeleteComplete"
    />
    <div v-if="pageInfo.hasNextPage || pageInfo.hasPreviousPage" class="gl-mt-5 gl-text-center">
      <gl-keyset-pagination v-bind="pageInfo" @prev="onPrev" @next="onNext" />
    </div>
  </div>
</template>
