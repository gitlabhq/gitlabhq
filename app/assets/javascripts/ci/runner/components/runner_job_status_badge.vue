<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';
import {
  I18N_JOB_STATUS_RUNNING,
  I18N_JOB_STATUS_IDLE,
  JOB_STATUS_RUNNING,
  JOB_STATUS_IDLE,
} from '../constants';

export default {
  components: {
    GlBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    jobStatus: {
      required: false,
      default: null,
      type: String,
    },
  },
  computed: {
    badge() {
      switch (this.jobStatus) {
        case JOB_STATUS_RUNNING:
          return {
            classes: 'gl-text-blue-600! gl-inset-border-1-gray-400 gl-border-blue-600!',
            label: I18N_JOB_STATUS_RUNNING,
          };
        case JOB_STATUS_IDLE:
          return {
            classes: 'gl-text-gray-700! gl-inset-border-1-gray-400 gl-border-gray-500!',
            label: I18N_JOB_STATUS_IDLE,
          };
        default:
          return null;
      }
    },
  },
};
</script>
<template>
  <gl-badge
    v-if="badge"
    v-bind="$attrs"
    class="gl-max-w-full gl-text-truncate gl-bg-transparent!"
    variant="muted"
    :class="badge.classes"
  >
    {{ badge.label }}
  </gl-badge>
</template>
