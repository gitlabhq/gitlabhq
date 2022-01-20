<script>
import { GlBadge } from '@gitlab/ui';
import { s__ } from '~/locale';

const STATUS_TEXT = {
  created: s__('Deployment|Created'),
  running: s__('Deployment|Running'),
  success: s__('Deployment|Success'),
  failed: s__('Deployment|Failed'),
  canceled: s__('Deployment|Cancelled'),
  skipped: s__('Deployment|Skipped'),
  blocked: s__('Deployment|Waiting'),
};

const STATUS_VARIANT = {
  success: 'success',
  running: 'info',
  failed: 'danger',
  created: 'neutral',
  canceled: 'neutral',
  skipped: 'neutral',
  blocked: 'neutral',
};

const STATUS_ICON = {
  success: 'status_success',
  running: 'status_running',
  failed: 'status_failed',
  created: 'status_created',
  canceled: 'status_canceled',
  skipped: 'status_skipped',
  blocked: 'status_manual',
};

export default {
  components: {
    GlBadge,
  },
  props: {
    status: {
      type: String,
      required: true,
    },
  },
  computed: {
    icon() {
      return STATUS_ICON[this.status];
    },
    text() {
      return STATUS_TEXT[this.status];
    },
    variant() {
      return STATUS_VARIANT[this.status];
    },
  },
};
</script>
<template>
  <gl-badge v-if="status" :icon="icon" :variant="variant">{{ text }}</gl-badge>
</template>
