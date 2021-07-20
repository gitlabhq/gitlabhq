<script>
import { GlIcon, GlLink, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { truncateSha } from '~/lib/utils/text_utility';
import { s__ } from '~/locale';
import getCommitSha from '~/pipeline_editor/graphql/queries/client/commit_sha.graphql';
import getPipelineQuery from '~/pipeline_editor/graphql/queries/client/pipeline.graphql';
import getPipelineEtag from '~/pipeline_editor/graphql/queries/client/pipeline_etag.graphql';
import {
  getQueryHeaders,
  toggleQueryPollingByVisibility,
} from '~/pipelines/components/graph/utils';
import CiIcon from '~/vue_shared/components/ci_icon.vue';

const POLL_INTERVAL = 10000;
export const i18n = {
  fetchError: s__('Pipeline|We are currently unable to fetch pipeline data'),
  fetchLoading: s__('Pipeline|Checking pipeline status'),
  pipelineInfo: s__(
    `Pipeline|Pipeline %{idStart}#%{idEnd} %{statusStart}%{statusEnd} for %{commitStart}%{commitEnd}`,
  ),
};

export default {
  i18n,
  components: {
    CiIcon,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
  },
  inject: ['projectFullPath'],
  apollo: {
    commitSha: {
      query: getCommitSha,
    },
    pipelineEtag: {
      query: getPipelineEtag,
    },
    pipeline: {
      context() {
        return getQueryHeaders(this.pipelineEtag);
      },
      query: getPipelineQuery,
      variables() {
        return {
          fullPath: this.projectFullPath,
          sha: this.commitSha,
        };
      },
      update: (data) => {
        const { id, commitPath = '', detailedStatus = {} } = data.project?.pipeline || {};

        return {
          id,
          commitPath,
          detailedStatus,
        };
      },
      error() {
        this.hasError = true;
      },
      pollInterval: POLL_INTERVAL,
    },
  },
  data() {
    return {
      commitSha: '',
      hasError: false,
    };
  },
  computed: {
    hasPipelineData() {
      return Boolean(this.pipeline?.id);
    },
    pipelineId() {
      return getIdFromGraphQLId(this.pipeline.id);
    },
    showLoadingState() {
      // the query is set to poll regularly, so if there is no pipeline data
      // (e.g. pipeline is null during fetch when the pipeline hasn't been
      // triggered yet), we can just show the loading state until the pipeline
      // details are ready to be fetched
      return this.$apollo.queries.pipeline.loading || (!this.hasPipelineData && !this.hasError);
    },
    shortSha() {
      return truncateSha(this.commitSha);
    },
    status() {
      return this.pipeline.detailedStatus;
    },
  },
  mounted() {
    toggleQueryPollingByVisibility(this.$apollo.queries.pipeline, POLL_INTERVAL);
  },
};
</script>

<template>
  <div class="gl-white-space-nowrap gl-max-w-full">
    <template v-if="showLoadingState">
      <gl-loading-icon class="gl-mr-auto gl-display-inline-block" size="sm" />
      <span data-testid="pipeline-loading-msg">{{ $options.i18n.fetchLoading }}</span>
    </template>
    <template v-else-if="hasError">
      <gl-icon class="gl-mr-auto" name="warning-solid" />
      <span data-testid="pipeline-error-msg">{{ $options.i18n.fetchError }}</span>
    </template>
    <template v-else>
      <a :href="status.detailsPath" class="gl-mr-auto">
        <ci-icon :status="status" :size="16" />
      </a>
      <span class="gl-font-weight-bold">
        <gl-sprintf :message="$options.i18n.pipelineInfo">
          <template #id="{ content }">
            <gl-link
              :href="status.detailsPath"
              class="pipeline-id gl-font-weight-normal pipeline-number"
              target="_blank"
              data-testid="pipeline-id"
            >
              {{ content }}{{ pipelineId }}</gl-link
            >
          </template>
          <template #status>{{ status.text }}</template>
          <template #commit>
            <gl-link
              :href="pipeline.commitPath"
              class="commit-sha gl-font-weight-normal"
              target="_blank"
              data-testid="pipeline-commit"
            >
              {{ shortSha }}
            </gl-link>
          </template>
        </gl-sprintf>
      </span>
    </template>
  </div>
</template>
