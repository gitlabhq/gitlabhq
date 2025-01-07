<script>
import { GlCard, GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';

import { PIPELINE_POLL_INTERVAL } from '~/ci/pipeline_editor/constants';
import { getQueryHeaders } from '~/ci/pipeline_details/graph/utils';
import getPipelineIidQuery from '~/ci/pipeline_editor/graphql/queries/get_pipeline_iid.query.graphql';
import getPipelineEtag from '~/ci/pipeline_editor/graphql/queries/client/pipeline_etag.query.graphql';

import PipelineSummary from '~/ci/common/pipeline_summary/pipeline_summary.vue';
import ValidationSegment from './validation_segment.vue';

export default {
  name: 'PipelineEditorHeader',
  i18n: {
    pipelineStatusText: s__('Pipeline|Checking pipeline status'),
    pipelineIidFetchError: s__('Pipelines|There was a problem fetching the pipeline iid.'),
  },
  components: {
    GlCard,
    GlLoadingIcon,
    PipelineSummary,
    ValidationSegment,
  },
  inject: ['projectFullPath'],
  props: {
    ciConfigData: {
      type: Object,
      required: true,
    },
    commitSha: {
      type: String,
      required: false,
      default: '',
    },
    isNewCiConfigFile: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      pipelineEtag: '',
      pipelineIid: '',
    };
  },
  apollo: {
    pipelineEtag: {
      query: getPipelineEtag,
      update(data) {
        return data.etags?.pipeline;
      },
    },
    pipelineIid: {
      context() {
        return getQueryHeaders(this.pipelineEtag);
      },
      query: getPipelineIidQuery,
      skip() {
        return !this.commitSha;
      },
      pollInterval: PIPELINE_POLL_INTERVAL,
      variables() {
        return {
          fullPath: this.projectFullPath,
          sha: this.commitSha,
        };
      },
      result({ data }) {
        this.handlePolling(data?.project?.pipeline?.id);
      },
      update({ project }) {
        return project?.pipeline?.iid || '';
      },
      error() {
        createAlert({ message: this.$options.i18n.pipelineIidFetchError });
      },
    },
  },
  computed: {
    isWaitingForIid() {
      return !this.pipelineIid;
    },
    showPipelineSummary() {
      return !this.isNewCiConfigFile;
    },
  },
  methods: {
    handlePolling(hasPipelineId) {
      if (hasPipelineId) {
        this.$apollo.queries.pipelineIid.stopPolling();
      } else {
        this.$apollo.queries.pipelineIid.startPolling(PIPELINE_POLL_INTERVAL);
      }
    },
  },
};
</script>
<template>
  <gl-card>
    <template v-if="showPipelineSummary" #header>
      <div v-if="isWaitingForIid" class="gl-mx-2 gl-flex gl-items-center">
        <gl-loading-icon class="gl-mr-4" />
        {{ $options.i18n.pipelineStatusText }}
      </div>
      <pipeline-summary
        v-else
        include-commit-info
        :iid="pipelineIid"
        :pipeline-etag="pipelineEtag"
        :full-path="projectFullPath"
      />
    </template>

    <validation-segment :ci-config="ciConfigData" />
  </gl-card>
</template>
