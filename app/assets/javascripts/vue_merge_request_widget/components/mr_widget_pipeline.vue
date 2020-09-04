<script>
/* eslint-disable vue/require-default-prop, vue/no-v-html */
import {
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlSprintf,
  GlTooltip,
  GlTooltipDirective,
} from '@gitlab/ui';
import mrWidgetPipelineMixin from 'ee_else_ce/vue_merge_request_widget/mixins/mr_widget_pipeline';
import { s__, n__ } from '~/locale';
import PipelineStage from '~/pipelines/components/pipelines_list/stage.vue';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';

export default {
  name: 'MRWidgetPipeline',
  components: {
    CiIcon,
    GlLink,
    GlLoadingIcon,
    GlIcon,
    GlSprintf,
    GlTooltip,
    PipelineStage,
    TooltipOnTruncate,
    LinkedPipelinesMiniList: () =>
      import('ee_component/vue_shared/components/linked_pipelines_mini_list.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
      return (
        this.pipeline.details && this.pipeline.details.stages && this.pipeline.details.stages.length
      );
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
    pipelineCoverageTooltipDescription() {
      return n__(
        'Coverage value for this pipeline was calculated by the coverage value of %d job.',
        'Coverage value for this pipeline was calculated by averaging the resulting coverage values of %d jobs.',
        this.buildsWithCoverage.length,
      );
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
      <div
        class="gl-flex-fill-1 gl-ml-5"
        tabindex="0"
        role="text"
        :aria-label="$options.errorText"
        data-testid="ci-error-message"
      >
        <gl-sprintf :message="$options.errorText">
          <template #link="{content}">
            <gl-link :href="mrTroubleshootingDocsPath">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </div>
    </template>
    <template v-else-if="!hasPipeline">
      <gl-loading-icon size="md" />
      <div class="gl-flex-fill-1 gl-display-flex gl-ml-5" data-testid="monitoring-pipeline-message">
        <span tabindex="0" role="text" :aria-label="$options.monitoringPipelineText">
          <gl-sprintf :message="$options.monitoringPipelineText" />
        </span>
        <gl-link
          :href="ciTroubleshootingDocsPath"
          target="_blank"
          class="gl-display-flex gl-align-items-center gl-ml-2"
          tabindex="0"
        >
          <gl-icon
            name="question"
            :size="12"
            tabindex="0"
            role="text"
            :aria-label="__('Link to go to GitLab pipeline documentation')"
          />
        </gl-link>
      </div>
    </template>
    <template v-else-if="hasPipeline">
      <a :href="status.details_path" class="align-self-start gl-mr-3">
        <ci-icon :status="status" :size="24" :borderless="true" class="add-border" />
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
                  :title="sourceBranch"
                  truncate-target="child"
                  class="label-branch label-truncate gl-font-weight-normal"
                  v-html="sourceBranchLink"
                />
              </template>
            </div>
            <div v-if="pipeline.coverage" class="coverage" data-testid="pipeline-coverage">
              {{ s__('Pipeline|Coverage') }} {{ pipeline.coverage }}%
              <span
                v-if="pipelineCoverageDelta"
                :class="coverageDeltaClass"
                data-testid="pipeline-coverage-delta"
                >({{ pipelineCoverageDelta }}%)</span
              >

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
            </div>
          </div>
        </div>
        <div>
          <span class="mr-widget-pipeline-graph">
            <span class="stage-cell">
              <linked-pipelines-mini-list v-if="triggeredBy.length" :triggered-by="triggeredBy" />
              <template v-if="hasStages">
                <div
                  v-for="(stage, i) in pipeline.details.stages"
                  :key="i"
                  :class="{
                    'has-downstream': hasDownstream(i),
                  }"
                  class="stage-container dropdown mr-widget-pipeline-stages"
                  data-testid="widget-mini-pipeline-graph"
                >
                  <pipeline-stage :stage="stage" />
                </div>
              </template>
            </span>
            <linked-pipelines-mini-list v-if="triggered.length" :triggered="triggered" />
          </span>
        </div>
      </div>
    </template>
  </div>
</template>
