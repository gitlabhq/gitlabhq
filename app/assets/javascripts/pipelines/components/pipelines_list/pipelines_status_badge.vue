<script>
import { CHILD_VIEW, TRACKING_CATEGORIES } from '~/pipelines/constants';
import CiBadgeLink from '~/vue_shared/components/ci_badge_link.vue';
import Tracking from '~/tracking';
import PipelinesTimeago from './time_ago.vue';

export default {
  components: {
    CiBadgeLink,
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
    <ci-badge-link
      class="gl-mb-3"
      :status="pipelineStatus"
      :show-text="!isChildView"
      data-qa-selector="pipeline_commit_status"
      @ciStatusBadgeClick="trackClick"
    />
    <pipelines-timeago :pipeline="pipeline" />
  </div>
</template>
