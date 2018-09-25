<script>
/* eslint-disable vue/require-default-prop */
import PipelineStage from '~/pipelines/components/stage.vue';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import Icon from '~/vue_shared/components/icon.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';

export default {
  name: 'MRWidgetPipeline',
  components: {
    PipelineStage,
    CiIcon,
    Icon,
    TooltipOnTruncate,
  },
  props: {
    pipeline: {
      type: Object,
      required: true,
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
    sourceBranchLink: {
      type: String,
      required: false,
    },
    sourceBranch: {
      type: String,
      required: false,
    },
  },
  computed: {
    hasPipeline() {
      return this.pipeline && Object.keys(this.pipeline).length > 0;
    },
    hasCIError() {
      return this.hasCi && !this.ciStatus;
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
  },
};
</script>

<template>
  <div
    v-if="hasPipeline || hasCIError"
    class="mr-widget-heading append-bottom-default"
  >
    <div class="ci-widget media">
      <template v-if="hasCIError">
        <div
          class="add-border ci-status-icon ci-status-icon-failed ci-error
          js-ci-error append-right-default"
        >
          <icon
            :size="32"
            name="status_failed_borderless"
          />
        </div>
        <div class="media-body">
          Could not connect to the CI server. Please check your settings and try again
        </div>
      </template>
      <template v-else-if="hasPipeline">
        <a
          :href="status.details_path"
          class="align-self-start append-right-default"
        >
          <ci-icon
            :status="status"
            :size="32"
            :borderless="true"
            class="add-border"
          />
        </a>
        <div class="ci-widget-container d-flex">
          <div class="ci-widget-content">
            <div class="media-body">
              <div class="font-weight-bold">
                Pipeline
                <a
                  :href="pipeline.path"
                  class="pipeline-id font-weight-normal pipeline-number"
                >#{{ pipeline.id }}</a>

                {{ pipeline.details.status.label }}

                <template v-if="hasCommitInfo">
                  for
                  <a
                    :href="pipeline.commit.commit_path"
                    class="commit-sha js-commit-link font-weight-normal"
                  >
                    {{ pipeline.commit.short_id }}</a>
                  on
                  <tooltip-on-truncate
                    :title="sourceBranch"
                    truncate-target="child"
                    class="label-branch label-truncate"
                    v-html="sourceBranchLink"
                  />
                </template>
              </div>
              <div
                v-if="pipeline.coverage"
                class="coverage"
              >
                Coverage {{ pipeline.coverage }}%
              </div>
            </div>
          </div>
          <div>
            <span class="mr-widget-pipeline-graph">
              <span
                v-if="hasStages"
                class="stage-cell"
              >
                <div
                  v-for="(stage, i) in pipeline.details.stages"
                  :key="i"
                  class="stage-container dropdown js-mini-pipeline-graph mr-widget-pipeline-stages"
                >
                  <pipeline-stage :stage="stage" />
                </div>
              </span>
            </span>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>
