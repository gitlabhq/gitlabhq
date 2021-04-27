<script>
import { GlBadge, GlIcon, GlLink, GlSafeHtmlDirective } from '@gitlab/ui';

export default {
  components: {
    GlBadge,
    GlIcon,
    GlLink,
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
  },
  props: {
    feature: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div class="gl-pb-7 gl-pt-5 gl-px-5 gl-border-b-1 gl-border-b-solid gl-border-b-gray-100">
    <gl-link
      :href="feature.url"
      target="_blank"
      class="whats-new-item-title-link"
      data-track-event="click_whats_new_item"
      :data-track-label="feature.title"
      :data-track-property="feature.url"
    >
      <h5 class="gl-font-lg" data-test-id="feature-title">{{ feature.title }}</h5>
    </gl-link>
    <div v-if="feature.packages" class="gl-mb-3">
      <gl-badge
        v-for="packageName in feature.packages"
        :key="packageName"
        size="sm"
        class="whats-new-item-badge gl-mr-2 gl-py-1!"
      >
        <gl-icon name="license" />{{ packageName }}
      </gl-badge>
    </div>
    <gl-link
      :href="feature.url"
      target="_blank"
      data-track-event="click_whats_new_item"
      :data-track-label="feature.title"
      :data-track-property="feature.url"
    >
      <img
        :alt="feature.title"
        :src="feature.image_url"
        class="img-thumbnail gl-px-8 gl-py-3 whats-new-item-image"
      />
    </gl-link>
    <div v-safe-html="feature.body" class="gl-pt-3"></div>
    <gl-link
      :href="feature.url"
      target="_blank"
      data-track-event="click_whats_new_item"
      :data-track-label="feature.title"
      :data-track-property="feature.url"
      >{{ __('Learn more') }}</gl-link
    >
  </div>
</template>
