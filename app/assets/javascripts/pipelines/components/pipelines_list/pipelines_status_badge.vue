<script>
import CodeQualityWalkthrough from '~/code_quality_walkthrough/components/step.vue';
import { PIPELINE_STATUSES } from '~/code_quality_walkthrough/constants';
import { CHILD_VIEW } from '~/pipelines/constants';
import CiBadge from '~/vue_shared/components/ci_badge_link.vue';

export default {
  components: {
    CodeQualityWalkthrough,
    CiBadge,
  },
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
    viewType: {
      type: String,
      required: true,
    },
  },
  computed: {
    pipelineStatus() {
      return this.pipeline?.details?.status ?? {};
    },
    isChildView() {
      return this.viewType === CHILD_VIEW;
    },
    shouldRenderCodeQualityWalkthrough() {
      return Object.values(PIPELINE_STATUSES).includes(this.pipelineStatus.group);
    },
    codeQualityStep() {
      const prefix = [PIPELINE_STATUSES.successWithWarnings, PIPELINE_STATUSES.failed].includes(
        this.pipelineStatus.group,
      )
        ? 'failed'
        : this.pipelineStatus.group;
      return `${prefix}_pipeline`;
    },
    codeQualityBuildPath() {
      return this.pipeline?.details?.code_quality_build_path;
    },
  },
};
</script>

<template>
  <div>
    <ci-badge
      id="js-code-quality-walkthrough"
      :status="pipelineStatus"
      :show-text="!isChildView"
      :icon-classes="'gl-vertical-align-middle!'"
      data-qa-selector="pipeline_commit_status"
    />
    <code-quality-walkthrough
      v-if="shouldRenderCodeQualityWalkthrough"
      :step="codeQualityStep"
      :link="codeQualityBuildPath"
    />
  </div>
</template>
