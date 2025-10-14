<script>
import { GlAlert, GlSkeletonLoader } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { getMarkdown } from '~/rest_api';

export default {
  components: { GlAlert, GlSkeletonLoader },
  directives: {
    SafeHtml,
  },
  inheritAttrs: false,
  props: {
    value: {
      type: String,
      required: true,
    },
    fallbackOnError: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      markdown: '',
      loading: true,
      error: false,
    };
  },
  mounted() {
    this.renderMarkdown();
  },
  methods: {
    async renderMarkdown() {
      this.loading = true;

      try {
        const { data } = await getMarkdown({ text: this.value, gfm: true });
        this.markdown = data.html;
      } catch (e) {
        Sentry.captureException(e);
        this.error = true;
      } finally {
        this.loading = false;
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-skeleton-loader v-if="loading" :width="200" :lines="2" />
    <template v-else-if="error">
      <gl-alert :dismissible="false" variant="danger">
        <span>{{ __('Failed to format markdown.') }}</span>
        <span v-if="fallbackOnError">{{ __('Value rendered as plain text.') }}</span>
      </gl-alert>
      <div v-if="fallbackOnError" data-testid="raw-value">{{ value }}</div>
    </template>
    <div v-else-if="markdown" v-safe-html="markdown" data-testid="markdown" class="md"></div>
  </div>
</template>
