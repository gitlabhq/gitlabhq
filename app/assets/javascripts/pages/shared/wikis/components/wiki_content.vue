<script>
import { GlSkeletonLoader, GlAlert } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { handleLocationHash } from '~/lib/utils/common_utils';
import { renderGFM } from '~/behaviors/markdown/render_gfm';

export default {
  components: {
    GlSkeletonLoader,
    GlAlert,
  },
  directives: {
    SafeHtml,
  },
  props: {
    getWikiContentUrl: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isLoadingContent: false,
      loadingContentFailed: false,
      content: null,
    };
  },
  mounted() {
    this.loadWikiContent();
  },
  methods: {
    async loadWikiContent() {
      this.loadingContentFailed = false;
      this.isLoadingContent = true;

      try {
        const {
          data: { content },
        } = await axios.get(this.getWikiContentUrl, { params: { render_html: true } });
        this.content = content;

        this.$nextTick()
          .then(() => {
            renderGFM(this.$refs.content);
            handleLocationHash();
          })
          .catch(() =>
            createAlert({
              message: this.$options.i18n.renderingContentFailed,
            }),
          );
      } catch (e) {
        this.loadingContentFailed = true;
      } finally {
        this.isLoadingContent = false;
      }
    },
  },
  i18n: {
    loadingContentFailed: __(
      'The content for this wiki page failed to load. To fix this error, reload the page.',
    ),
    retryLoadingContent: __('Retry'),
    renderingContentFailed: __('The content for this wiki page failed to render.'),
  },
};
</script>
<template>
  <gl-skeleton-loader v-if="isLoadingContent" :width="830" :height="113">
    <rect width="540" height="16" rx="4" />
    <rect y="49" width="701" height="16" rx="4" />
    <rect y="24" width="830" height="16" rx="4" />
    <rect y="73" width="540" height="16" rx="4" />
  </gl-skeleton-loader>
  <gl-alert
    v-else-if="loadingContentFailed"
    :dismissible="false"
    variant="danger"
    :primary-button-text="$options.i18n.retryLoadingContent"
    @primaryAction="loadWikiContent"
  >
    {{ $options.i18n.loadingContentFailed }}
  </gl-alert>
  <div
    v-else-if="!loadingContentFailed && !isLoadingContent"
    ref="content"
    v-safe-html="content"
    data-testid="wiki-page-content"
    class="js-wiki-page-content md"
  ></div>
</template>
