<script>
import { GlBadge, GlIcon, GlLink, GlSafeHtmlDirective, GlButton } from '@gitlab/ui';
import { dateInWords, isValidDate } from '~/lib/utils/datetime_utility';

export default {
  components: {
    GlBadge,
    GlIcon,
    GlLink,
    GlButton,
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
  computed: {
    releaseDate() {
      const { published_at } = this.feature;
      const date = new Date(published_at);

      if (!isValidDate(date) || date.getTime() === 0) {
        return '';
      }

      return dateInWords(date);
    },
  },
  safeHtmlConfig: { ADD_ATTR: ['target'] },
};
</script>

<template>
  <div class="gl-py-6 gl-px-6 gl-border-b-1 gl-border-b-solid gl-border-b-gray-100">
    <gl-link
      :href="feature.url"
      target="_blank"
      class="gl-display-block"
      data-track-event="click_whats_new_item"
      :data-track-label="feature.title"
      :data-track-property="feature.url"
    >
      <div
        class="whats-new-item-image gl-bg-size-cover"
        :style="`background-image: url(${feature.image_url});`"
      >
        <span class="gl-sr-only">{{ feature.title }}</span>
      </div>
    </gl-link>
    <gl-link
      :href="feature.url"
      target="_blank"
      class="whats-new-item-title-link gl-display-block gl-mt-4 gl-mb-1"
      data-track-event="click_whats_new_item"
      :data-track-label="feature.title"
      :data-track-property="feature.url"
    >
      <h5 class="gl-font-lg gl-my-0" data-test-id="feature-title">{{ feature.title }}</h5>
    </gl-link>
    <div v-if="releaseDate" class="gl-mb-3" data-testid="release-date">{{ releaseDate }}</div>
    <div v-if="feature.packages" class="gl-mb-3">
      <gl-badge
        v-for="packageName in feature.packages"
        :key="packageName"
        size="md"
        class="whats-new-item-badge gl-mr-2"
      >
        <gl-icon name="license" />{{ packageName }}
      </gl-badge>
    </div>
    <div
      v-safe-html:[$options.safeHtmlConfig]="feature.body"
      class="gl-pt-3 gl-line-height-20"
    ></div>
    <gl-button
      :href="feature.url"
      target="_blank"
      data-track-event="click_whats_new_item"
      :data-track-label="feature.title"
      :data-track-property="feature.url"
    >
      {{ __('Learn more') }} <gl-icon name="arrow-right" />
    </gl-button>
  </div>
</template>
