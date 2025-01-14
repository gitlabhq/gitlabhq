<script>
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
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
    CiIcon,
  },
  props: {
    status: {
      type: String,
      required: true,
    },
    href: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    icon() {
      return STATUS_ICON[this.status];
    },
    text() {
      return STATUS_TEXT[this.status];
    },
    statusObject() {
      return {
        text: this.text,
        icon: this.icon,
        detailsPath: this.href,
      };
    },
  },
};
</script>
<template>
  <ci-icon v-if="status" :status="statusObject" show-status-text class="!gl-border-0" />
</template>
