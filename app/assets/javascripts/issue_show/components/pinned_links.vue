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
      default: '',
    },
    publishedIncidentUrl: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>

<template>
  <div class="border-bottom gl-mb-6 gl-display-flex gl-justify-content-start">
    <div v-if="publishedIncidentUrl" class="gl-pr-3">
      <gl-link
        :href="publishedIncidentUrl"
        target="_blank"
        class="btn btn-inverted btn-secondary btn-sm text-dark mb-3"
        data-testid="publishedIncidentUrl"
      >
        <icon name="tanuki" :size="14" />
        <strong class="vertical-align-top">{{ __('Published on status page') }}</strong>
      </gl-link>
    </div>
    <div v-if="zoomMeetingUrl">
      <gl-link
        :href="zoomMeetingUrl"
        target="_blank"
        class="btn btn-inverted btn-secondary btn-sm text-dark mb-3"
        data-testid="zoomMeetingUrl"
      >
        <icon name="brand-zoom" :size="14" />
        <strong class="vertical-align-top">{{ __('Join Zoom meeting') }}</strong>
      </gl-link>
    </div>
  </div>
</template>
