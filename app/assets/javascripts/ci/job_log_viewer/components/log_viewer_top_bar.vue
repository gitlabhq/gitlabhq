<script>
import { GlExperimentBadge } from '@gitlab/ui';

export default {
  name: 'LogViewerTopBar',
  components: {
    GlExperimentBadge,
  },
  props: {
    hasTimestamps: {
      type: Boolean,
      default: () => false,
      required: false,
    },
  },
};
</script>
<template>
  <div class="job-log-viewer-top-bar gl-flex gl-items-center gl-justify-between">
    <div>
      <span v-if="hasTimestamps" data-testid="utc-hint">
        {{ s__('Job|Log timestamps in UTC.') }}
      </span>
    </div>
    <div>
      {{ s__('Job|Full log viewer') }}
      <gl-experiment-badge />
    </div>
  </div>
</template>
