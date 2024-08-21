<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';
import {
  I18N_JOB_STATUS_ACTIVE,
  I18N_JOB_STATUS_IDLE,
  JOB_STATUS_ACTIVE,
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
        case JOB_STATUS_ACTIVE:
          return {
            classes: '!gl-text-blue-600 gl-shadow-inner-1-gray-400 !gl-border-blue-600',
            label: I18N_JOB_STATUS_ACTIVE,
          };
        case JOB_STATUS_IDLE:
          return {
            classes: '!gl-text-gray-700 gl-shadow-inner-1-gray-400 !gl-border-gray-500',
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
    class="!gl-bg-transparent"
    variant="muted"
    :class="badge.classes"
  >
    <span class="gl-truncate">
      {{ badge.label }}
    </span>
  </gl-badge>
</template>
