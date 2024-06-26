<script>
/* eslint-disable vue/require-default-prop */
import {
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlSprintf,
  GlTooltip,
  GlTooltipDirective,
  GlButton,
} from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { s__, n__ } from '~/locale';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { keepLatestDownstreamPipelines } from '~/ci/pipeline_details/utils/parsing_utils';
import PipelineArtifacts from '~/ci/pipelines_page/components/pipelines_artifacts.vue';
import LegacyPipelineMiniGraph from '~/ci/pipeline_mini_graph/legacy_pipeline_mini_graph.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import runPipelineMixin from '../mixins/run_pipeline';
import { MT_MERGE_STRATEGY } from '../constants';

export default {
  name: 'MRWidgetPipeline',
  components: {
    CiIcon,
    GlLink,
    GlLoadingIcon,
    GlIcon,
    GlSprintf,
    GlTooltip,
    GlButton,
    LegacyPipelineMiniGraph,
    PipelineArtifacts,
    TimeAgoTooltip,
    TooltipOnTruncate,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  mixins: [runPipelineMixin],
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
    pipelineCoverageDelta: {
      type: String,
      required: false,
    },
    buildsWithCoverage: {
      type: Array,
      required: false,
      default: () => [],
    },
    // This prop needs to be camelCase, html attributes are case insensive
    // https://vuejs.org/v2/guide/components.html#camelCase-vs-kebab-case
    hasCi: {
      type: Boolean,
      required: false,
    },
    ciStatus: {
      type: String,
      required: false,
    },
    pipelineMustSucceed: {
      type: Boolean,
      required: false,
    },
    sourceBranchLink: {
      type: String,
      required: false,
    },
    sourceBranch: {
      type: String,
      required: false,
    },
    mrTroubleshootingDocsPath: {
      type: String,
      required: true,
    },
    ciTroubleshootingDocsPath: {
      type: String,
      required: true,
    },
    mergeStrategy: {
      type: String,
      required: false,
      default: '',
    },
    retargeted: {
      type: Boolean,
      required: false,
      default: false,
    },
    detatchedPipeline: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      isCreatingPipeline: false,
    };
  },
  computed: {
    downstreamPipelines() {
      const downstream = this.pipeline.triggered;
      return keepLatestDownstreamPipelines(downstream);
    },
    hasPipeline() {
      return this.pipeline && Object.keys(this.pipeline).length > 0;
    },
    hasCIError() {
      return this.hasPipeline && !this.ciStatus;
    },
    status() {
      return this.pipeline.details && this.pipeline.details.status
        ? this.pipeline.details.status
        : {};
    },
    artifacts() {
      return this.pipeline?.details?.artifacts;
    },
    hasStages() {
      return this.pipeline?.details?.stages?.length > 0;
    },
    hasCommitInfo() {
      return this.pipeline.commit && Object.keys(this.pipeline.commit).length > 0;
    },
    isMergeRequestPipeline() {
      return Boolean(this.pipeline.flags && this.pipeline.flags.merge_request_pipeline);
    },
    showSourceBranch() {
      return Boolean(this.pipeline.ref.branch);
    },
    finishedAt() {
      return this.pipeline?.details?.finished_at;
    },
    coverageDeltaClass() {
      const delta = this.pipelineCoverageDelta;
      if (delta && parseFloat(delta) > 0) {
        return 'text-success';
      }
      if (delta && parseFloat(delta) < 0) {
        return 'text-danger';
      }
      return '';
    },
    pipelineCoverageJobNumberText() {
      return n__('from %d job', 'from %d jobs', this.buildsWithCoverage.length);
    },
    pipelineCoverageTooltipDeltaDescription() {
      const delta = parseFloat(this.pipelineCoverageDelta) || 0;
      if (delta > 0) {
        return s__('Pipeline|This change will increase the overall test coverage if merged.');
      }
      if (delta < 0) {
        return s__('Pipeline|This change will decrease the overall test coverage if merged.');
      }
      return s__('Pipeline|This change will not change the overall test coverage if merged.');
    },
    pipelineCoverageTooltipDescription() {
      return n__(
        'Test coverage value for this pipeline was calculated by the coverage value of %d job.',
        'Test coverage value for this pipeline was calculated by averaging the resulting coverage values of %d jobs.',
        this.buildsWithCoverage.length,
      );
    },
    isMergeTrain() {
      return this.mergeStrategy === MT_MERGE_STRATEGY;
    },
  },
  errorText: s__(
    'Pipeline|Could not retrieve the pipeline status. For troubleshooting steps, read the %{linkStart}documentation%{linkEnd}.',
  ),
  monitoringPipelineText: s__('Pipeline|Checking pipeline status.'),
};
</script>
<template>
  <div class="ci-widget media">
    <template v-if="hasCIError">
      <gl-icon name="status_failed" class="gl-text-red-500" :size="24" />
      <p class="gl-flex-grow-1 gl-ml-5 gl-mb-0" data-testid="ci-error-message">
        <gl-sprintf :message="$options.errorText">
          <template #link="{ content }">
            <gl-link :href="mrTroubleshootingDocsPath">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
    </template>
    <template v-else-if="retargeted">
      <gl-icon name="status_canceled" class="gl-align-self-center gl-mr-3" />
      <p class="gl-flex-grow-1 gl-flex gl-ml-3 gl-mb-0 text-muted" data-testid="retargeted-message">
        {{
          __(
            'You should run a new pipeline, because the target branch has changed for this merge request.',
          )
        }}
      </p>
      <gl-button
        v-if="detatchedPipeline"
        category="tertiary"
        variant="confirm"
        size="small"
        :loading="isCreatingPipeline"
        data-testid="run-pipeline-button"
        @click="runPipeline"
      >
        {{ __('Run pipeline') }}
      </gl-button>
    </template>
    <template v-else-if="!hasPipeline">
      <gl-loading-icon size="sm" />
      <p
        class="gl-flex-grow-1 gl-display-flex gl-ml-3 gl-mb-0"
        data-testid="monitoring-pipeline-message"
      >
        {{ $options.monitoringPipelineText }}
        <gl-link
          v-gl-tooltip
          :href="ciTroubleshootingDocsPath"
          target="_blank"
          :title="__('Get more information about troubleshooting pipelines')"
          class="gl-display-flex gl-align-items-center gl-ml-2"
        >
          <gl-icon
            name="question-o"
            :aria-label="__('Link to go to GitLab pipeline documentation')"
          />
        </gl-link>
      </p>
    </template>
    <template v-else-if="hasPipeline">
      <ci-icon :status="status" class="gl-align-self-start gl-mt-2 gl-mr-3" />
      <div class="ci-widget-container d-flex">
        <div class="ci-widget-content">
          <div class="media-body">
            <div
              data-testid="pipeline-info-container"
              class="gl-display-flex gl-flex-wrap gl-align-items-center gl-justify-content-space-between"
            >
              <p
                class="mr-pipeline-title gl-align-self-start gl-m-0! gl-mr-3! gl-font-weight-bold gl-text-gray-900"
              >
                {{ pipeline.details.event_type_name }}
                <gl-link :href="pipeline.path" class="pipeline-id" data-testid="pipeline-id"
                  >#{{ pipeline.id }}</gl-link
                >
                {{ pipeline.details.status.label }}
              </p>
              <div
                class="gl-align-items-center gl-display-inline-flex gl-flex-grow-1 gl-justify-content-space-between"
              >
                <legacy-pipeline-mini-graph
                  v-if="pipeline.details.stages"
                  :downstream-pipelines="downstreamPipelines"
                  :is-merge-train="isMergeTrain"
                  :pipeline-path="pipeline.path"
                  :stages="pipeline.details.stages"
                  :upstream-pipeline="pipeline.triggered_by"
                />
                <pipeline-artifacts
                  :pipeline-id="pipeline.id"
                  :artifacts="artifacts"
                  class="gl-ml-3"
                />
              </div>
            </div>
            <p data-testid="pipeline-details-container" class="gl-font-sm gl-text-gray-500 gl-m-0">
              {{ pipeline.details.event_type_name }} {{ pipeline.details.status.label }}
              <template v-if="hasCommitInfo">
                {{ s__('Pipeline|for') }}
                <gl-link
                  :href="pipeline.commit.commit_path"
                  class="commit-sha-container"
                  data-testid="commit-link"
                  >{{ pipeline.commit.short_id }}</gl-link
                >
              </template>
              <template v-if="showSourceBranch">
                {{ s__('Pipeline|on') }}
                <tooltip-on-truncate
                  v-safe-html="sourceBranchLink"
                  :title="sourceBranch"
                  truncate-target="child"
                  class="label-branch label-truncate ref-container"
                />
              </template>
              <template v-if="finishedAt">
                <time-ago-tooltip
                  :time="finishedAt"
                  tooltip-placement="bottom"
                  data-testid="finished-at"
                />
              </template>
            </p>
            <div v-if="pipeline.coverage" class="coverage gl-mt-1" data-testid="pipeline-coverage">
              {{ s__('Pipeline|Test coverage') }} {{ pipeline.coverage }}%
              <span
                v-if="pipelineCoverageDelta"
                ref="pipelineCoverageDelta"
                :class="coverageDeltaClass"
                data-testid="pipeline-coverage-delta"
              >
                ({{ pipelineCoverageDelta }}%)
              </span>
              {{ pipelineCoverageJobNumberText }}
              <span ref="pipelineCoverageQuestion">
                <gl-icon name="question-o" :size="12" />
              </span>
              <gl-tooltip
                :target="() => $refs.pipelineCoverageQuestion"
                data-testid="pipeline-coverage-tooltip"
              >
                {{ pipelineCoverageTooltipDescription }}
                <div
                  v-for="(build, index) in buildsWithCoverage"
                  :key="`${build.name}-${index}`"
                  class="gl-mt-3 gl-text-left gl-px-4"
                >
                  {{ build.name }} ({{ build.coverage }}%)
                </div>
              </gl-tooltip>
              <gl-tooltip
                :target="() => $refs.pipelineCoverageDelta"
                data-testid="pipeline-coverage-delta-tooltip"
              >
                {{ pipelineCoverageTooltipDeltaDescription }}
              </gl-tooltip>
            </div>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>
