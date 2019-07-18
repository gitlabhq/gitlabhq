<script>
import { GlLink } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
    GlLink,
  },
  props: {
    zoomMeetingUrl: {
      type: String,
      required: false,
      default: null,
    },
  },
};
</script>

<template>
  <div v-if="zoomMeetingUrl" class="border-bottom mb-3 mt-n2">
    <gl-link
      :href="zoomMeetingUrl"
      target="_blank"
      class="btn btn-inverted btn-secondary btn-sm text-dark mb-3"
    >
      <icon name="brand-zoom" :size="14" />
      <strong class="vertical-align-top">{{ __('Join Zoom meeting') }}</strong>
    </gl-link>
  </div>
</template>
