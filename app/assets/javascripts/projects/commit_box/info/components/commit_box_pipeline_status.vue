<script>
import { GlLoadingIcon, GlLink } from '@gitlab/ui';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import { createAlert } from '~/alert';
import {
  getQueryHeaders,
  toggleQueryPollingByVisibility,
} from '~/pipelines/components/graph/utils';
import getLatestPipelineStatusQuery from '../graphql/queries/get_latest_pipeline_status.query.graphql';
import { COMMIT_BOX_POLL_INTERVAL, PIPELINE_STATUS_FETCH_ERROR } from '../constants';

export default {
  PIPELINE_STATUS_FETCH_ERROR,
  components: {
    CiIcon,
    GlLoadingIcon,
    GlLink,
  },
  inject: {
    fullPath: {
      default: '',
    },
    iid: {
      default: '',
    },
    graphqlResourceEtag: {
      default: '',
    },
  },
  apollo: {
    pipelineStatus: {
      context() {
        return getQueryHeaders(this.graphqlResourceEtag);
      },
      query: getLatestPipelineStatusQuery,
      pollInterval: COMMIT_BOX_POLL_INTERVAL,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.iid,
        };
      },
      update({ project }) {
        return project?.pipeline?.detailedStatus || {};
      },
      error() {
        createAlert({ message: this.$options.PIPELINE_STATUS_FETCH_ERROR });
      },
    },
  },
  data() {
    return {
      pipelineStatus: {},
    };
  },
  computed: {
    loading() {
      return this.$apollo.queries.pipelineStatus.loading;
    },
  },
  mounted() {
    toggleQueryPollingByVisibility(this.$apollo.queries.pipelineStatus);
  },
};
</script>

<template>
  <div class="gl-display-inline-block gl-vertical-align-middle gl-mr-2">
    <gl-loading-icon v-if="loading" />
    <gl-link v-else :href="pipelineStatus.detailsPath">
      <ci-icon :status="pipelineStatus" :size="24" />
    </gl-link>
  </div>
</template>
