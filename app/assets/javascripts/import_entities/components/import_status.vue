<script>
import { GlIcon } from '@gitlab/ui';
import STATUS_MAP from '../constants';

export default {
  name: 'ImportStatus',
  components: {
    GlIcon,
  },
  props: {
    status: {
      type: String,
      required: true,
    },
  },

  computed: {
    mappedStatus() {
      return STATUS_MAP[this.status];
    },
  },
};
</script>

<template>
  <div>
    <gl-icon :name="mappedStatus.icon" :class="mappedStatus.iconClass" :size="12" class="gl-mr-2" />
    <span>{{ mappedStatus.text }}</span>
  </div>
</template>
