<script>
import { TRACKING_CATEGORIES } from '~/ci/constants';
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
    <ci-badge-link class="gl-mb-3" :status="pipelineStatus" @ciStatusBadgeClick="trackClick" />
    <pipelines-timeago :pipeline="pipeline" />
  </div>
</template>
