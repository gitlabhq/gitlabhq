<script>
import { GlButton, GlIcon, GlLink, GlLoadingIcon, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { truncateSha } from '~/lib/utils/text_utility';
import { s__ } from '~/locale';
import getPipelineQuery from '~/ci/pipeline_editor/graphql/queries/pipeline.query.graphql';
import getPipelineEtag from '~/ci/pipeline_editor/graphql/queries/client/pipeline_etag.query.graphql';
import { getQueryHeaders, toggleQueryPollingByVisibility } from '~/ci/pipeline_details/graph/utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import PipelineMiniGraph from '~/ci/pipeline_mini_graph/pipeline_mini_graph.vue';
import PipelineEditorMiniGraph from './pipeline_editor_mini_graph.vue';

const POLL_INTERVAL = 10000;
export const i18n = {
  fetchError: s__('Pipeline|We are currently unable to fetch pipeline data'),
  fetchLoading: s__('Pipeline|Checking pipeline status'),
  pipelineInfo: s__(
    `Pipeline|Pipeline %{idStart}#%{idEnd} %{statusStart}%{statusEnd} for %{commitStart}%{commitEnd}`,
  ),
  viewBtn: s__('Pipeline|View pipeline'),
  viewCommit: s__('Pipeline|View commit'),
};

export default {
  i18n,
  components: {
    CiIcon,
    GlButton,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
    PipelineEditorMiniGraph,
    PipelineMiniGraph,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['projectFullPath'],
  props: {
    commitSha: {
      type: String,
      required: false,
      default: '',
    },
  },
  apollo: {
    pipelineEtag: {
      query: getPipelineEtag,
      update(data) {
        return data.etags?.pipeline;
      },
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
      update(data) {
        const {
          id,
          iid,
          commit = {},
          detailedStatus = {},
          stages,
          status,
        } = data.project?.pipeline || {};

        return {
          id,
          iid,
          commit,
          detailedStatus,
          stages,
          status,
        };
      },
      result(res) {
        if (res.data?.project?.pipeline) {
          this.hasError = false;
        }
      },
      error() {
        this.hasError = true;
      },
      pollInterval: POLL_INTERVAL,
    },
  },
  data() {
    return {
      hasError: false,
    };
  },
  computed: {
    commitText() {
      const shortSha = truncateSha(this.commitSha);
      const commitTitle = this.pipeline.commit.title || '';

      if (commitTitle.length > 0) {
        return `${shortSha}: ${commitTitle}`;
      }

      return shortSha;
    },
    hasPipelineData() {
      return Boolean(this.pipeline?.id);
    },
    isUsingPipelineMiniGraphQueries() {
      return this.glFeatures.ciGraphqlPipelineMiniGraph;
    },
    pipelineId() {
      return getIdFromGraphQLId(this.pipeline.id);
    },
    showLoadingState() {
      // the query is set to poll regularly, so if there is no pipeline data
      // (e.g. pipeline is null during fetch when the pipeline hasn't been
      // triggered yet), we can just show the loading state until the pipeline
      // details are ready to be fetched
      return (
        this.$apollo.queries.pipeline.loading ||
        this.commitSha.length === 0 ||
        (!this.hasPipelineData && !this.hasError)
      );
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
  <div
    class="gl-display-flex gl-justify-content-space-between gl-align-items-center gl-flex-wrap gl-w-full"
  >
    <template v-if="showLoadingState">
      <div>
        <gl-loading-icon class="gl-mr-auto gl-display-inline-block" size="sm" />
        <span data-testid="pipeline-loading-msg">{{ $options.i18n.fetchLoading }}</span>
      </div>
    </template>
    <template v-else-if="hasError">
      <div>
        <gl-icon class="gl-mr-auto" name="warning-solid" />
        <span data-testid="pipeline-error-msg">{{ $options.i18n.fetchError }}</span>
      </div>
    </template>
    <template v-else>
      <div class="gl-text-truncate gl-md-max-w-50p gl-mr-1">
        <ci-icon :status="status" data-testid="pipeline-status-icon" />
        <span class="gl-font-bold">
          <gl-sprintf :message="$options.i18n.pipelineInfo">
            <template #id="{ content }">
              <span data-testid="pipeline-id"> {{ content }}{{ pipelineId }} </span>
            </template>
            <template #status>{{ status.text }}</template>
            <template #commit>
              <gl-link
                v-gl-tooltip.hover
                :href="pipeline.commit.webPath"
                :title="$options.i18n.viewCommit"
                data-testid="pipeline-commit"
              >
                {{ commitText }}
              </gl-link>
            </template>
          </gl-sprintf>
        </span>
      </div>
      <div class="gl-display-flex gl-flex-wrap-wrap">
        <pipeline-mini-graph
          v-if="isUsingPipelineMiniGraphQueries"
          :full-path="projectFullPath"
          :iid="pipeline.iid"
          :pipeline-etag="pipelineEtag"
        />
        <pipeline-editor-mini-graph v-else :pipeline="pipeline" v-on="$listeners" />
        <gl-button
          class="gl-ml-3 gl-align-self-center"
          size="small"
          :href="status.detailsPath"
          data-testid="pipeline-view-btn"
        >
          {{ $options.i18n.viewBtn }}
        </gl-button>
      </div>
    </template>
  </div>
</template>
