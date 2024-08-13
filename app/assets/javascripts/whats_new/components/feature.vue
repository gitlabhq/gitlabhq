<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlBadge, GlIcon, GlLink, GlButton } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { dateInWords, isValidDate } from '~/lib/utils/datetime_utility';

export default {
  components: {
    GlBadge,
    GlIcon,
    GlLink,
    GlButton,
  },
  directives: {
    SafeHtml,
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
      const date = new Date(`${published_at}T00:00:00`); // eslint-disable-line camelcase

      if (!isValidDate(date) || date.getTime() === 0) {
        return '';
      }

      return dateInWords(date);
    },
  },
};
</script>

<template>
  <div class="gl-py-6 gl-px-6 gl-border-b-1 gl-border-b-solid gl-border-b-gray-100">
    <gl-link
      v-if="feature.image_url"
      :href="feature.documentation_link"
      target="_blank"
      class="gl-block"
      data-testid="whats-new-image-link"
      data-track-action="click_whats_new_item"
      :data-track-label="feature.name"
      :data-track-property="feature.documentation_link"
    >
      <div
        class="gl-bg-cover gl-border-subtle gl-h-31"
        :style="`background-image: url(${feature.image_url});`"
      >
        <span class="gl-sr-only">{{ feature.name }}</span>
      </div>
    </gl-link>
    <gl-link
      :href="feature.documentation_link"
      target="_blank"
      class="gl-block gl-mt-4 gl-mb-1 !gl-text-inherit"
      data-track-action="click_whats_new_item"
      data-testid="whats-new-item-link"
      :data-track-label="feature.name"
      :data-track-property="feature.documentation_link"
    >
      <h5 class="gl-font-lg gl-my-0" data-testid="feature-name">{{ feature.name }}</h5>
    </gl-link>
    <div v-if="releaseDate" class="gl-mb-3" data-testid="release-date">{{ releaseDate }}</div>
    <div v-if="feature.available_in" class="gl-mb-3">
      <gl-badge
        v-for="packageName in feature.available_in"
        :key="packageName"
        variant="tier"
        icon="license"
        class="gl-mr-2"
      >
        {{ packageName }}
      </gl-badge>
    </div>
    <div
      v-safe-html:[$options.safeHtmlConfig]="feature.description"
      class="gl-pt-3 gl-leading-20"
    ></div>
    <gl-button
      :href="feature.documentation_link"
      target="_blank"
      data-track-action="click_whats_new_item"
      :data-track-label="feature.name"
      :data-track-property="feature.documentation_link"
    >
      {{ __('Learn more') }} <gl-icon name="arrow-right" />
    </gl-button>
  </div>
</template>
