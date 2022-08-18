<script>
import { GlLoadingIcon } from '@gitlab/ui';
import ciIcon from '~/vue_shared/components/ci_icon.vue';

export default {
  components: {
    ciIcon,
    GlLoadingIcon,
  },
  props: {
    status: {
      type: String,
      required: true,
    },
  },
  computed: {
    isLoading() {
      return this.status === 'loading';
    },
    statusObj() {
      return {
        group: this.status,
        icon: `status_${this.status}`,
      };
    },
  },
};
</script>
<template>
  <div class="gl-display-flex gl-align-self-start">
    <div class="square s24 h-auto d-flex-center gl-mr-3">
      <div v-if="isLoading" class="mr-widget-icon gl-display-inline-flex">
        <gl-loading-icon size="md" class="mr-loading-icon gl-display-inline-flex" />
      </div>
      <ci-icon v-else :status="statusObj" :size="24" />
    </div>
  </div>
</template>
