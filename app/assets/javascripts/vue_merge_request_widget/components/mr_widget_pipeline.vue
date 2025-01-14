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
import PipelineMiniGraph from '~/ci/pipeline_mini_graph/pipeline_mini_graph.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import mergeRequestEventTypeQuery from '../queries/merge_request_event_type.query.graphql';
import runPipelineMixin from '../mixins/run_pipeline';
import {
  PIPELINE_EVENT_TYPE_MERGE_REQUEST,
  PIPELINE_EVENT_TYPE_MERGE_TRAIN,
  PIPELINE_EVENT_TYPE_MERGED_RESULT,
  PIPELINE_EVENT_TYPE_MAP,
} from '../constants';

export default {
  name: 'MRWidgetPipeline',
  apollo: {
    mergeRequestEventType: {
      query: mergeRequestEventTypeQuery,
      variables() {
        return {
          projectPath: this.targetProjectFullPath,
          iid: `${this.iid}`,
        };
      },
      skip() {
        return !this.retargeted;
      },
      update: (d) => d.project?.mergeRequest?.pipelines?.nodes?.[0]?.mergeRequestEventType,
    },
  },
  components: {
    CiIcon,
    GlLink,
    GlLoadingIcon,
    GlIcon,
    GlSprintf,
    GlTooltip,
    GlButton,
    PipelineMiniGraph,
    PipelineArtifacts,
    TimeAgoTooltip,
    TooltipOnTruncate,
    HelpPopover,
    HelpIcon,
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
    pipelineEtag: {
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
    targetProjectFullPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isCreatingPipeline: false,
      mergeRequestEventType: null,
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
      return this.pipeline?.details?.status || {};
    },
    artifacts() {
      return this.pipeline?.details?.artifacts;
    },
    hasArtifacts() {
      return Boolean(this.pipeline?.details?.artifacts?.length);
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
        return 'gl-text-success';
      }
      if (delta && parseFloat(delta) < 0) {
        return 'gl-text-danger';
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
      return Boolean(this.pipeline.flags?.merge_train_pipeline);
    },
    showPipelineTypeHelpPopover() {
      return [
        PIPELINE_EVENT_TYPE_MERGE_TRAIN,
        PIPELINE_EVENT_TYPE_MERGED_RESULT,
        PIPELINE_EVENT_TYPE_MERGE_REQUEST,
      ].includes(this.pipeline?.details?.event_type_name);
    },
    pipelineTypeHelpPopoverOptions() {
      const eventTypeName = this.pipeline?.details?.event_type_name;

      return PIPELINE_EVENT_TYPE_MAP[eventTypeName] || { title: '', content: '' };
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
      <gl-icon name="status_failed" :size="24" variant="danger" />
      <p class="gl-mb-0 gl-ml-5 gl-grow" data-testid="ci-error-message">
        <gl-sprintf :message="$options.errorText">
          <template #link="{ content }">
            <gl-link :href="mrTroubleshootingDocsPath">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
    </template>
    <template v-else-if="retargeted">
      <gl-icon name="status_canceled" class="gl-mr-3 gl-self-center" />
      <p class="gl-mb-0 gl-ml-3 gl-flex gl-grow gl-text-subtle" data-testid="retargeted-message">
        {{
          __(
            'You should run a new pipeline, because the target branch has changed for this merge request.',
          )
        }}
      </p>
      <gl-button
        v-if="mergeRequestEventType"
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
      <p class="gl-mb-0 gl-ml-3 gl-flex gl-grow" data-testid="monitoring-pipeline-message">
        {{ $options.monitoringPipelineText }}
        <gl-link
          v-gl-tooltip
          :href="ciTroubleshootingDocsPath"
          target="_blank"
          :title="__('Get more information about troubleshooting pipelines')"
          class="gl-ml-2 gl-flex gl-items-center"
        >
          <help-icon :aria-label="__('Link to go to GitLab pipeline documentation')" />
        </gl-link>
      </p>
    </template>
    <template v-else-if="hasPipeline">
      <ci-icon :status="status" class="gl-mr-3 gl-mt-2 gl-self-start" />
      <div class="ci-widget-container gl-flex">
        <div class="ci-widget-content">
          <div class="media-body">
            <div
              data-testid="pipeline-info-container"
              class="gl-flex gl-flex-wrap gl-items-center gl-justify-between"
            >
              <p
                class="mr-pipeline-title !gl-m-0 !gl-mr-3 gl-self-start gl-font-bold gl-text-default"
              >
                {{ pipeline.details.event_type_name }}
                <gl-link :href="pipeline.path" class="pipeline-id" data-testid="pipeline-id"
                  >#{{ pipeline.id }}</gl-link
                >
                {{ pipeline.details.status.label }}
              </p>
              <div class="gl-inline-flex gl-grow gl-items-center gl-justify-between">
                <div>
                  <pipeline-mini-graph
                    v-if="pipeline.details.stages"
                    :downstream-pipelines="downstreamPipelines"
                    :is-merge-train="isMergeTrain"
                    :pipeline-path="pipeline.path"
                    :pipeline-stages="pipeline.details.stages"
                    :upstream-pipeline="pipeline.triggered_by"
                  />
                </div>
                <pipeline-artifacts
                  v-if="hasArtifacts"
                  :pipeline-id="pipeline.id"
                  :artifacts="artifacts"
                  class="gl-ml-3"
                />
              </div>
            </div>

            <div class="gl-flex gl-flex-wrap gl-items-center">
              <p class="gl-m-0 gl-text-sm gl-text-subtle" data-testid="pipeline-details-container">
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
              <help-popover
                v-if="showPipelineTypeHelpPopover"
                class="gl-ml-2 gl-inline-flex"
                :options="pipelineTypeHelpPopoverOptions"
              />
            </div>

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
                <help-icon />
              </span>
              <gl-tooltip
                :target="() => $refs.pipelineCoverageQuestion"
                data-testid="pipeline-coverage-tooltip"
              >
                {{ pipelineCoverageTooltipDescription }}
                <div
                  v-for="(build, index) in buildsWithCoverage"
                  :key="`${build.name}-${index}`"
                  class="gl-mt-3 gl-px-4 gl-text-left"
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
