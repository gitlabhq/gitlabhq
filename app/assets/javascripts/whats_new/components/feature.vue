<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlBadge, GlIcon, GlLink, GlButton, GlDrawer } from '@gitlab/ui';
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
    showUnread: {
      type: Boolean,
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
    toggleArticleAndEmit() {
      if (this.articleOpen) {
        this.$emit('close-drawer');
      }

      this.toggleArticle();
    },
    toggleAndMarkArticle() {
      if (this.showUnread) {
        this.$emit('mark-article-as-read');
      }
      this.toggleArticle();
    },
  },
};
</script>

<template>
  <h4
    v-if="feature.releaseHeading"
    class="whats-new-release-heading gl-heading-5 gl-mb-0 gl-mt-3 gl-px-3"
    data-testid="whats-new-release-heading"
  >
    {{ formattedReleaseHeading }}
  </h4>
  <div v-else>
    <gl-button
      class="gl-my-3 !gl-border-transparent !gl-p-0 focus:!gl-focus-inset"
      category="primary"
      variant="default"
      block
      data-testid="whats-new-article-toggle"
      @click="toggleAndMarkArticle"
    >
      <div class="gl-flex gl-flex-col gl-gap-3 gl-px-3 gl-py-4 gl-text-left">
        <h3
          class="gl-m-0 gl-text-wrap gl-text-lg gl-text-default"
          data-testid="toggle-feature-name"
        >
          <gl-icon
            v-if="showUnread"
            name="status-active"
            :size="8"
            class="gl-my-1 gl-mr-1"
            variant="info"
            data-testid="unread-article-icon"
          />
          {{ feature.name }}
        </h3>
        <p
          class="gl-mb-0 gl-line-clamp-3 gl-text-wrap gl-leading-20 gl-text-subtle"
          data-testid="feature-description"
        >
          {{ sanitizedDescription }}
        </p>
        <div class="gl-flex gl-flex-wrap gl-gap-2">
          <gl-badge
            v-for="packageName in feature.available_in"
            :key="`toggle-${packageName}`"
            variant="tier"
            icon="check-xs"
            class="!gl-gap-0"
          >
            {{ packageName }}
          </gl-badge>
        </div>
      </div>
    </gl-button>
    <hr class="gl-border-t gl-m-0" />
    <gl-drawer
      class="whats-new-article-drawer gl-transition-none"
      :open="articleOpen"
      :header-height="getDrawerHeaderHeight"
      header-sticky
      @close="toggleArticleAndEmit"
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
        <h3 class="gl-heading-3-fixed gl-my-0 gl-ml-2 gl-mr-auto">
          {{ formattedReleaseHeading }}
        </h3>
      </template>
      <div class="gl-flex gl-flex-col gl-gap-3">
        <h3 class="gl-m-0 gl-text-lg" data-testid="feature-name">
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
        <div v-if="releaseDate" data-testid="release-date">{{ releaseDate }}</div>
        <div v-if="feature.available_in" class="gl-mb-3 gl-mt-2 gl-flex gl-flex-wrap gl-gap-2">
          <gl-badge
            v-for="packageName in feature.available_in"
            :key="packageName"
            variant="tier"
            icon="check-xs"
            class="!gl-gap-0"
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
          class="gl-mt-3 gl-leading-20"
        ></div>
        <gl-link
          :href="feature.documentation_link"
          target="_blank"
          show-external-icon
          data-track-action="click_whats_new_item"
          :data-track-label="feature.name"
          :data-track-property="feature.documentation_link"
          :aria-describedby="descriptionId"
        >
          {{ __('Learn more') }}
        </gl-link>
      </div>
    </gl-drawer>
  </div>
</template>
