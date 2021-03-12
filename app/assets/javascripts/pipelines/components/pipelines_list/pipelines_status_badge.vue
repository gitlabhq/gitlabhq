<script>
import { CHILD_VIEW } from '~/pipelines/constants';
import CiBadge from '~/vue_shared/components/ci_badge_link.vue';

export default {
  components: {
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
  },
};
</script>

<template>
  <ci-badge
    :status="pipelineStatus"
    :show-text="!isChildView"
    :icon-classes="'gl-vertical-align-middle!'"
    data-qa-selector="pipeline_commit_status"
  />
</template>
