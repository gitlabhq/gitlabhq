<script>
import { GlIcon } from '@gitlab/ui';
import { STATUS_CLOSED, STATUS_MERGED } from '~/issues/constants';
import StatusIcon from './extensions/status_icon.vue';

export default {
  components: {
    StatusIcon,
    GlIcon,
  },
  props: {
    status: {
      type: String,
      required: true,
    },
  },
  computed: {
    isClosed() {
      return this.status === STATUS_CLOSED;
    },
    isLoading() {
      return this.status === 'loading';
    },
    isMerged() {
      return this.status === STATUS_MERGED;
    },
  },
};
</script>
<template>
  <div class="gl-w-6 gl-h-6 gl-display-flex gl-align-self-center gl-mr-3">
    <div class="gl-display-flex gl-m-auto">
      <gl-icon v-if="isMerged" name="merge" :size="16" class="gl-text-blue-500" />
      <gl-icon v-else-if="isClosed" name="merge-request-close" :size="16" class="gl-text-red-500" />
      <gl-icon v-else-if="status === 'approval'" name="approval" :size="16" />
      <status-icon v-else :is-loading="isLoading" :icon-name="status" :level="1" class="gl-m-0!" />
    </div>
  </div>
</template>
