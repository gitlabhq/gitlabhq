<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlBadge, GlIcon, GlLink, GlButton, GlTruncate, GlDrawer } from '@gitlab/ui';
import { localeDateFormat, newDate } from '~/lib/utils/datetime_utility';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { sanitize } from '~/lib/dompurify';
import { slugify } from '~/lib/utils/text_utility';
import { sprintf, __, s__ } from '~/locale';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';

export default {
  components: {
    GlBadge,
    GlIcon,
    GlLink,
    GlButton,
    GlTruncate,
    GlDrawer,
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
  data() {
    return {
      articleOpen: false,
    };
  },
  computed: {
    formattedReleaseHeading() {
      if (!this.feature.release) {
        return __('Other updates');
      }

      return sprintf(s__('FeaturedUpdate|%{releaseNumber} Release'), {
        releaseNumber: this.formattedReleaseNumber,
      });
    },
    formattedReleaseNumber() {
      if (this.feature.release % 1 === 0) {
        return Number(this.feature.release).toFixed(1);
      }

      return this.feature.release;
    },
    releaseDate() {
      if (!this.feature.published_at) {
        return undefined;
      }
      return localeDateFormat.asDate.format(newDate(this.feature.published_at));
    },
    descriptionId() {
      return `${slugify(this.feature.name)}-feature-description`;
    },
    sanitizedDescription() {
      return sanitize(this.feature.description, {
        ALLOWED_TAGS: [],
      });
    },
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    articleToggleAriaLabel() {
      return this.articleOpen
        ? s__('FeaturedUpdate|Close article')
        : s__('FeaturedUpdate|Open article');
    },
  },
  methods: {
    toggleArticle() {
      this.articleOpen = !this.articleOpen;
    },
  },
};
</script>

<template>
  <div v-if="feature.releaseHeading">
    <h5 class="gl-m-3" data-testid="whats-new-release-heading">
      {{ formattedReleaseHeading }}
    </h5>
  </div>
  <div v-else class="gl-px-3">
    <gl-button
      class="gl-my-3 !gl-p-0"
      category="primary"
      variant="default"
      block
      data-testid="whats-new-article-toggle"
      @click="toggleArticle"
    >
      <div class="gl-p-5 gl-text-left">
        <gl-badge
          v-for="packageName in feature.available_in"
          :key="`toggle-${packageName}`"
          variant="info"
          class="gl-mr-2 !gl-px-3 !gl-py-1"
        >
          {{ packageName }}
        </gl-badge>
        <h3
          class="gl-my-2 gl-text-wrap gl-text-lg gl-leading-24 gl-text-default"
          data-testid="toggle-feature-name"
        >
          {{ feature.name }}
        </h3>
        <gl-truncate :text="sanitizedDescription" class="gl-leading-20" />
      </div>
    </gl-button>
    <gl-drawer
      class="whats-new-article-drawer"
      :open="articleOpen"
      :header-height="getDrawerHeaderHeight"
      @close="toggleArticle"
    >
      <template #title>
        <gl-button
          category="tertiary"
          icon="chevron-lg-left"
          size="small"
          data-testid="whats-new-article-close"
          :aria-label="articleToggleAriaLabel"
          @click="toggleArticle"
        />
        <h3 class="gl-heading-3-fixed gl-my-3 gl-ml-3 gl-mr-auto">
          {{ __("What's new at GitLab") }}
        </h3>
      </template>
      <div class="gl-m-3 gl-h-auto gl-overflow-y-auto">
        <h3 class="gl-mb-3 gl-mt-0 gl-text-lg" data-testid="feature-name">
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
        <div v-if="feature.available_in" class="gl-mb-6">
          <gl-badge
            v-for="packageName in feature.available_in"
            :key="packageName"
            variant="info"
            class="gl-mr-2"
          >
            {{ packageName }}
          </gl-badge>
        </div>
        <gl-link
          v-if="feature.image_url"
          :href="feature.documentation_link"
          target="_blank"
          class="gl-border gl-block gl-overflow-hidden gl-rounded-base"
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
        <div
          :id="descriptionId"
          v-safe-html:[$options.safeHtmlConfig]="feature.description"
          class="gl-pt-6 gl-leading-20"
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
    </gl-drawer>
  </div>
</template>
