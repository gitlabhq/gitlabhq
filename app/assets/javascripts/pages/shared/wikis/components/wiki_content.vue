<script>
import Vue from 'vue';
import { GlSkeletonLoader, GlAlert } from '@gitlab/ui';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { handleLocationHash } from '~/lib/utils/common_utils';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { __ } from '~/locale';
import { getHeadingsFromDOM } from '~/content_editor/services/table_of_contents_utils';
import TableOfContents from './table_of_contents.vue';

const TableOfContentsComponent = Vue.extend(TableOfContents);

export default {
  components: {
    GlSkeletonLoader,
    GlAlert,
  },
  directives: {
    SafeHtml,
  },

  inject: ['contentApi'],
  data() {
    return {
      content: '',
      isLoadingContent: false,
      loadingContentFailed: false,
      headings: [],
    };
  },
  mounted() {
    this.loadWikiContent();
  },
  methods: {
    async renderHeadingsInSidebar() {
      const headings = getHeadingsFromDOM(this.$refs.content);
      if (!headings.length) return;

      const tocComponent = new TableOfContentsComponent({ propsData: { headings } }).$mount();
      const tocContainer = document.querySelector('.js-wiki-toc');

      tocContainer.innerHTML = '';
      tocContainer.appendChild(tocComponent.$el);
    },

    async loadWikiContent() {
      this.loadingContentFailed = false;
      this.isLoadingContent = true;

      try {
        const {
          data: { content },
        } = await axios.get(this.contentApi, { params: { render_html: true } });
        this.content = content;

        this.$nextTick()
          .then(() => {
            renderGFM(this.$refs.content);
            handleLocationHash();

            this.renderHeadingsInSidebar();
          })
          .catch(() => {
            createAlert({
              message: this.$options.i18n.renderingContentFailed,
            });
          });
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
