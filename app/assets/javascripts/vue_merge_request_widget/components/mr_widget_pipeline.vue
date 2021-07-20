<script>
/* eslint-disable vue/require-default-prop */
import {
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlSprintf,
  GlTooltip,
  GlTooltipDirective,
  GlSafeHtmlDirective,
} from '@gitlab/ui';
import mrWidgetPipelineMixin from 'ee_else_ce/vue_merge_request_widget/mixins/mr_widget_pipeline';
import { s__, n__ } from '~/locale';
import PipelineMiniGraph from '~/pipelines/components/pipelines_list/pipeline_mini_graph.vue';
import PipelineArtifacts from '~/pipelines/components/pipelines_list/pipelines_artifacts.vue';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';
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
    PipelineArtifacts,
    PipelineMiniGraph,
    TimeAgoTooltip,
    TooltipOnTruncate,
    LinkedPipelinesMiniList: () =>
      import('ee_component/vue_shared/components/linked_pipelines_mini_list.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml: GlSafeHtmlDirective,
  },
  mixins: [mrWidgetPipelineMixin],
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
  },
  computed: {
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
    <template v-else-if="!hasPipeline">
      <gl-loading-icon size="md" />
      <p
        class="gl-flex-grow-1 gl-display-flex gl-ml-3 gl-mb-0"
        data-testid="monitoring-pipeline-message"
      >
        {{ $options.monitoringPipelineText }}
        <gl-link
          v-gl-tooltip
          :href="ciTroubleshootingDocsPath"
          target="_blank"
          :title="__('About this feature')"
          class="gl-display-flex gl-align-items-center gl-ml-2"
        >
          <gl-icon
            name="question"
            :aria-label="__('Link to go to GitLab pipeline documentation')"
          />
        </gl-link>
      </p>
    </template>
    <template v-else-if="hasPipeline">
      <a :href="status.details_path" class="gl-align-self-center gl-mr-3">
        <ci-icon :status="status" :size="24" />
      </a>
      <div class="ci-widget-container d-flex">
        <div class="ci-widget-content">
          <div class="media-body">
            <div
              class="gl-font-weight-bold"
              data-testid="pipeline-info-container"
              data-qa-selector="merge_request_pipeline_info_content"
            >
              {{ pipeline.details.name }}
              <gl-link
                :href="pipeline.path"
                class="pipeline-id gl-font-weight-normal pipeline-number"
                data-testid="pipeline-id"
                data-qa-selector="pipeline_link"
                >#{{ pipeline.id }}</gl-link
              >
              {{ pipeline.details.status.label }}
              <template v-if="hasCommitInfo">
                {{ s__('Pipeline|for') }}
                <gl-link
                  :href="pipeline.commit.commit_path"
                  class="commit-sha gl-font-weight-normal"
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
                  class="label-branch label-truncate gl-font-weight-normal"
                />
              </template>
              <template v-if="finishedAt">
                <time-ago-tooltip
                  :time="finishedAt"
                  tooltip-placement="bottom"
                  data-testid="finished-at"
                />
              </template>
            </div>
            <div v-if="pipeline.coverage" class="coverage" data-testid="pipeline-coverage">
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
                <gl-icon name="question" :size="12" />
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
        <div>
          <span class="mr-widget-pipeline-graph">
            <span class="stage-cell">
              <linked-pipelines-mini-list v-if="triggeredBy.length" :triggered-by="triggeredBy" />
              <pipeline-mini-graph
                v-if="hasStages"
                class="gl-display-inline-block"
                stages-class="mr-widget-pipeline-stages"
                :stages="pipeline.details.stages"
                :is-merge-train="isMergeTrain"
              />
            </span>
            <linked-pipelines-mini-list v-if="triggered.length" :triggered="triggered" />
            <pipeline-artifacts :pipeline-id="pipeline.id" class="gl-ml-3" />
          </span>
        </div>
      </div>
    </template>
  </div>
</template>
