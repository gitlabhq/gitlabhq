<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlBadge, GlIcon, GlLink, GlButton } from '@gitlab/ui';
import { localeDateFormat, newDate } from '~/lib/utils/datetime_utility';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { slugify } from '~/lib/utils/text_utility';

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
      if (!this.feature.published_at) {
        return undefined;
      }
      return localeDateFormat.asDate.format(newDate(this.feature.published_at));
    },
    descriptionId() {
      return `${slugify(this.feature.name)}-feature-description`;
    },
  },
};
</script>

<template>
  <div class="gl-border-b-1 gl-border-b-default gl-px-6 gl-py-6 gl-border-b-solid">
    <gl-link
      v-if="feature.image_url"
      :href="feature.documentation_link"
      target="_blank"
      class="gl-block"
      data-testid="whats-new-image-link"
      data-track-action="click_whats_new_item"
      :aria-hidden="true"
      tabindex="-1"
      :data-track-label="feature.name"
      :data-track-property="feature.documentation_link"
    >
      <div
        class="gl-h-31 gl-border-subtle gl-bg-cover"
        :style="`background-image: url(${feature.image_url});`"
      >
        <span class="gl-sr-only">{{ feature.name }}</span>
      </div>
    </gl-link>
    <h3 class="gl-mb-1 gl-mt-4 gl-text-lg" data-testid="feature-name">
      <gl-link
        :href="feature.documentation_link"
        target="_blank"
        class="!gl-text-inherit"
        data-track-action="click_whats_new_item"
        data-testid="whats-new-item-link"
        :data-track-label="feature.name"
        :data-track-property="feature.documentation_link"
      >
        {{ feature.name }}
      </gl-link>
    </h3>
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
      :id="descriptionId"
      v-safe-html:[$options.safeHtmlConfig]="feature.description"
      class="gl-pt-3 gl-leading-20"
    ></div>
    <gl-button
      :href="feature.documentation_link"
      target="_blank"
      data-track-action="click_whats_new_item"
      :data-track-label="feature.name"
      :data-track-property="feature.documentation_link"
      :aria-describedby="descriptionId"
    >
      {{ __('Learn more') }} <gl-icon name="arrow-right" />
    </gl-button>
  </div>
</template>
