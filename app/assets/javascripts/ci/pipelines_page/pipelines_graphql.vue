<script>
/*
  This component is the GraphQL version of `ci/pipelines_page/pipelines.vue`
  and is meant to eventually replace it.
*/
import { GlKeysetPagination, GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import PipelinesTable from '~/ci/common/pipelines_table.vue';
import getPipelinesQuery from './graphql/queries/get_pipelines.query.graphql';
import { PIPELINES_PER_PAGE } from './constants';

const DEFAULT_PAGINATION = {
  first: PIPELINES_PER_PAGE,
  last: null,
  before: null,
  after: null,
};

export default {
  components: {
    GlKeysetPagination,
    GlLoadingIcon,
    PipelinesTable,
  },
  inject: {
    fullPath: {
      default: '',
    },
  },
  apollo: {
    pipelines: {
      query: getPipelinesQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          first: this.pagination.first,
          last: this.pagination.last,
          after: this.pagination.after,
          before: this.pagination.before,
        };
      },
      update(data) {
        return {
          list: data?.project?.pipelines?.nodes || [],
          pageInfo: data?.project?.pipelines?.pageInfo || {},
        };
      },
      error() {
        createAlert({
          message: s__('Pipelines|An error occurred while loading pipelines'),
        });
      },
    },
  },
  data() {
    return {
      pipelines: {
        list: [],
        pageInfo: {},
      },
      pagination: {
        ...DEFAULT_PAGINATION,
      },
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.pipelines.loading;
    },
    showPagination() {
      return this.pipelines?.pageInfo?.hasNextPage || this.pipelines?.pageInfo?.hasPreviousPage;
    },
  },
  methods: {
    nextPage() {
      this.pagination = {
        after: this.pipelines?.pageInfo?.endCursor,
        before: null,
        first: PIPELINES_PER_PAGE,
        last: null,
      };
    },
    prevPage() {
      this.pagination = {
        after: null,
        before: this.pipelines?.pageInfo?.startCursor,
        first: null,
        last: PIPELINES_PER_PAGE,
      };
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="lg" />

    <pipelines-table v-else :pipelines="pipelines.list" />

    <div class="gl-mt-5 gl-flex gl-justify-center">
      <gl-keyset-pagination
        v-if="showPagination && !isLoading"
        v-bind="pipelines.pageInfo"
        @prev="prevPage"
        @next="nextPage"
      />
    </div>
  </div>
</template>
