<script>
import { GlBadge } from '@gitlab/ui';
import StatusIcon from '~/vue_merge_request_widget/components/widget/status_icon.vue';

export default {
  components: {
    GlBadge,
    StatusIcon,
  },
  props: {
    to: {
      type: String,
      required: true,
    },
    statusIcon: {
      type: String,
      required: true,
    },
    count: {
      type: Number,
      required: false,
      default: null,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <router-link
    :to="{ name: to }"
    active-class="gl-font-bold gl-bg-strong"
    exact
    class="gl-flex gl-items-center gl-rounded-base gl-p-2 gl-text-default hover:gl-bg-strong hover:gl-text-default hover:gl-no-underline"
  >
    <status-icon :icon-name="statusIcon" :is-loading="isLoading" />
    <slot></slot>
    <gl-badge v-if="count !== null" class="gl-ml-auto gl-mr-2" variant="neutral"
      ><span class="gl-font-bold">{{ count }}</span></gl-badge
    >
  </router-link>
</template>
