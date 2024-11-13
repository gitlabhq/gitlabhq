<script>
import { GlIcon } from '@gitlab/ui';
import { STATUS_CLOSED, STATUS_MERGED, STATUS_EMPTY } from '~/issues/constants';
import StatusIcon from './widget/status_icon.vue';

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
    isEmpty() {
      return this.status === STATUS_EMPTY;
    },
  },
};
</script>
<template>
  <div class="gl-mr-3 gl-flex gl-h-6 gl-w-6 gl-self-start">
    <div class="gl-m-auto gl-flex">
      <gl-icon v-if="isMerged" name="merge" :size="16" variant="info" />
      <gl-icon v-else-if="isClosed" name="merge-request-close" :size="16" variant="danger" />
      <gl-icon v-else-if="status === 'approval'" name="approval" :size="16" />
      <status-icon v-else-if="isEmpty" icon-name="neutral" :level="1" class="!gl-m-0" />
      <status-icon v-else :is-loading="isLoading" :icon-name="status" :level="1" class="!gl-m-0" />
    </div>
  </div>
</template>
