<script>
import { GlLink, GlExperimentBadge } from '@gitlab/ui';

export default {
  name: 'LogViewerTopBar',
  components: {
    GlLink,
    GlExperimentBadge,
  },
};
</script>
<template>
  <div
    class="job-log-viewer-top-bar gl-display-flex gl-align-items-center gl-justify-content-space-between"
  >
    <div>{{ s__('Job|Full log viewer') }}<gl-experiment-badge /></div>
    <div>
      <gl-link href="https://gitlab.com/gitlab-org/gitlab/-/issues/454817" target="_blank">{{
        s__('Job|Give feedback')
      }}</gl-link>
    </div>
  </div>
</template>
