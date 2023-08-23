<script>
import { GlLoadingIcon } from '@gitlab/ui';
import getMergeRequestPipelines from '~/pipelines/graphql/queries/get_merge_request_pipelines.query.graphql';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import { getQueryHeaders } from '~/pipelines/components/graph/utils';
import { graphqlEtagMergeRequestPipelines } from '~/pipelines/utils';

export default {
  components: {
    GlLoadingIcon,
  },
  inject: ['graphqlPath', 'mergeRequestId', 'targetProjectFullPath'],
  data() {
    return {
      pipelines: [],
    };
  },
  apollo: {
    pipelines: {
      query: getMergeRequestPipelines,
      context() {
        return getQueryHeaders(this.graphqlResourceEtag);
      },
      pollInterval: 10000,
      variables() {
        return {
          fullPath: this.targetProjectFullPath,
          mergeRequestIid: String(this.mergeRequestId),
        };
      },
      update(data) {
        return data?.project?.mergeRequest?.pipelines?.nodes || [];
      },
      error() {
        createAlert({ message: this.$options.i18n.fetchError });
      },
    },
  },
  computed: {
    graphqlResourceEtag() {
      return graphqlEtagMergeRequestPipelines(this.graphqlPath, this.mergeRequestId);
    },
    isLoading() {
      return this.$apollo.queries.pipelines.loading;
    },
  },
  i18n: {
    fetchError: __("There was an error fetching this merge request's pipelines."),
  },
};
</script>
<template>
  <div class="gl-mt-3">
    <gl-loading-icon v-if="isLoading" size="lg" />
    <ul v-else>
      <li v-for="pipeline in pipelines" :key="pipeline.id">{{ pipeline.path }}</li>
    </ul>
  </div>
</template>
