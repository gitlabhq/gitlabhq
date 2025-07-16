<script>
import { GlCard, GlButton } from '@gitlab/ui';
import { InternalEvents } from '~/tracking';

export default {
  name: 'FeaturedCard',
  components: {
    GlCard,
    GlButton,
  },
  mixins: [InternalEvents.mixin()],
  props: {
    title: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: true,
    },
    buttonLink: {
      type: String,
      required: true,
    },
    trackingEvent: {
      type: String,
      required: true,
    },
  },
  methods: {
    handleLearnMoreClick() {
      this.trackEvent(this.trackingEvent);
    },
  },
};
</script>

<template>
  <gl-card class="featured-update-card gl-border-[#cbbbf2] gl-bg-cover" body-class="gl-p-6">
    <div>
      <h3 class="gl-mt-0 gl-text-lg">{{ title }}</h3>
      {{ description }}
    </div>
    <gl-button
      variant="confirm"
      class="gl-mt-6"
      :href="buttonLink"
      target="_blank"
      @click="handleLearnMoreClick"
      >{{ __('Learn more') }}</gl-button
    >
  </gl-card>
</template>

<style scoped>
.featured-update-card {
  background-image: url('duo_banner_background.svg?url');
}
</style>
