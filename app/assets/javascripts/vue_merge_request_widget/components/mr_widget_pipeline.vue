<script>
/* eslint-disable vue/require-default-prop */
import PipelineStage from '~/pipelines/components/stage.vue';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  name: 'MRWidgetPipeline',
  components: {
    PipelineStage,
    CiIcon,
    Icon,
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
    class="mr-widget-heading"
  >
    <div class="ci-widget media">
      <template v-if="hasCIError">
        <div class="ci-status-icon ci-status-icon-failed ci-error js-ci-error append-right-10">
          <icon name="status_failed" />
        </div>
        <div class="media-body">
          Could not connect to the CI server. Please check your settings and try again
        </div>
      </template>
      <template v-else-if="hasPipeline">
        <a
          class="append-right-10"
          :href="status.details_path"
        >
          <ci-icon :status="status" />
        </a>

        <div class="media-body">
          Pipeline
          <a
            :href="pipeline.path"
            class="pipeline-id"
          >
            #{{ pipeline.id }}
          </a>

          {{ pipeline.details.status.label }}

          <template v-if="hasCommitInfo">
            for

            <a
              :href="pipeline.commit.commit_path"
              class="commit-sha js-commit-link"
            >
            {{ pipeline.commit.short_id }}</a>.
          </template>

          <span class="mr-widget-pipeline-graph">
            <span
              class="stage-cell"
              v-if="hasStages"
            >
              <div
                v-for="(stage, i) in pipeline.details.stages"
                :key="i"
                class="stage-container dropdown js-mini-pipeline-graph"
              >
                <pipeline-stage :stage="stage" />
              </div>
            </span>
          </span>

          <template v-if="pipeline.coverage">
            Coverage {{ pipeline.coverage }}%
          </template>
        </div>
      </template>
    </div>
  </div>
</template>
