<script>
import { GlLink } from '@gitlab/ui';
import ExperimentBadge from '~/vue_shared/components/badges/experiment_badge.vue';

export default {
  name: 'LogViewerFeedbackPopover',
  components: {
    GlLink,
    ExperimentBadge,
  },
};
</script>
<template>
  <div
    class="job-log-viewer-top-bar gl-display-flex gl-align-items-center gl-justify-content-space-between"
  >
    <div>{{ s__('Job|Full log viewer') }} <experiment-badge class="gl-display-inline" /></div>
    <div>
      <gl-link href="https://gitlab.com/gitlab-org/gitlab/-/issues/454817" target="_blank">{{
        s__('Job|Feedback issue')
      }}</gl-link>
    </div>
  </div>
</template>
