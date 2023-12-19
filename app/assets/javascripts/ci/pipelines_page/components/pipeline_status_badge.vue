<script>
import { TRACKING_CATEGORIES } from '~/ci/constants';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import Tracking from '~/tracking';
import PipelinesTimeago from './time_ago.vue';

export default {
  components: {
    CiIcon,
    PipelinesTimeago,
  },
  mixins: [Tracking.mixin()],
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
  },
  computed: {
    pipelineStatus() {
      return this.pipeline?.details?.status ?? {};
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
    <ci-icon
      class="gl-mb-2"
      :status="pipelineStatus"
      show-status-text
      @ciStatusBadgeClick="trackClick"
    />
    <pipelines-timeago :pipeline="pipeline" />
  </div>
</template>
