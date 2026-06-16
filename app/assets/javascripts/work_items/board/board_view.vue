<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

import getBoardNamespaceStatusesQuery from 'ee_else_ce/work_items/board/graphql/get_namespace_statuses.query.graphql';
import ColumnGroup from './components/column_group.vue';

export default {
  name: 'BoardView',
  components: {
    GlLoadingIcon,
    ColumnGroup,
  },
  props: {
    rootPageFullPath: {
      type: String,
      required: true,
    },
    queryVariables: {
      type: Object,
      required: true,
    },
  },
  emits: ['set-error'],
  data() {
    return {
      groupBy: { property: 'status' },
      groupByValues: [],
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.groupByValues.loading;
    },
  },
  apollo: {
    groupByValues: {
      query: getBoardNamespaceStatusesQuery,
      variables() {
        return { fullPath: this.rootPageFullPath };
      },
      update(data) {
        return data?.namespace?.rootNamespace?.statuses?.nodes ?? [];
      },
      error(error) {
        this.$emit(
          'set-error',
          s__(
            'WorkItemBoard|Something went wrong when fetching the board columns. Please try again.',
          ),
        );
        Sentry.captureException(error);
      },
    },
  },
};
</script>

<template>
  <div
    class="gl-flex gl-w-full gl-gap-3 gl-overflow-x-auto gl-py-5"
    style="height: calc(100dvh - 220px - 2rem)"
  >
    <gl-loading-icon v-if="isLoading && groupByValues.length === 0" size="lg" class="gl-m-auto" />
    <column-group
      v-for="value in groupByValues"
      :key="value.id"
      :value="value"
      :group-property="groupBy.property"
      :root-page-full-path="rootPageFullPath"
      :base-query-variables="queryVariables"
    />
  </div>
</template>
