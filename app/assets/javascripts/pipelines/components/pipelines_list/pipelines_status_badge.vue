<script>
import { CHILD_VIEW, TRACKING_CATEGORIES } from '~/pipelines/constants';
import CiBadge from '~/vue_shared/components/ci_badge_link.vue';
import Tracking from '~/tracking';
import PipelinesTimeago from './time_ago.vue';

export default {
  components: {
    CiBadge,
    PipelinesTimeago,
  },
  mixins: [Tracking.mixin()],
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
  methods: {
    trackClick() {
      this.track('click_ci_status_badge', { label: TRACKING_CATEGORIES.table });
    },
  },
};
</script>

<template>
  <div>
    <ci-badge
      class="gl-mb-3"
      :status="pipelineStatus"
      :show-text="!isChildView"
      :icon-classes="'gl-vertical-align-middle!'"
      data-qa-selector="pipeline_commit_status"
      @ciStatusBadgeClick="trackClick"
    />
    <pipelines-timeago class="gl-mt-3" :pipeline="pipeline" />
  </div>
</template>
