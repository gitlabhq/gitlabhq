<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import PipelinesTable from '~/ci/common/pipelines_table.vue';
import getPipelinesQuery from './graphql/queries/get_pipelines.query.graphql';

const defaultPagination = {
  first: 15,
  last: null,
  prevPageCursor: '',
  nextPageCursor: '',
  currentPage: 1,
};

export default {
  components: {
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
          prevPageCursor: this.pagination.prevPageCursor,
          nextPageCursor: this.pagination.nextPageCursor,
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
        ...defaultPagination,
      },
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.pipelines.loading;
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="lg" />
    <pipelines-table v-else :pipelines="pipelines.list" />
  </div>
</template>
