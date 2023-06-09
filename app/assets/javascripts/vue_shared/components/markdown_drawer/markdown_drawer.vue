<script>
import { GlDrawer, GlAlert, GlSkeletonLoader } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { s__ } from '~/locale';
import { contentTop } from '~/lib/utils/common_utils';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getRenderedMarkdown } from './utils/fetch';

export const cache = {};

export default {
  name: 'MarkdownDrawer',
  components: {
    GlDrawer,
    GlAlert,
    GlSkeletonLoader,
  },
  directives: {
    SafeHtml,
  },
  i18n: {
    alert: s__('MardownDrawer|Could not fetch help contents.'),
  },
  props: {
    documentPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      loading: false,
      hasFetchError: false,
      title: '',
      body: null,
      open: false,
      drawerTop: '0px',
    };
  },
  watch: {
    documentPath: {
      immediate: true,
      handler: 'fetchMarkdown',
    },
    open(open) {
      if (open && this.body) {
        this.renderGLFM();
      }
    },
  },
  methods: {
    async fetchMarkdown() {
      const cached = cache[this.documentPath];
      this.hasFetchError = false;
      this.title = '';
      if (cached) {
        this.title = cached.title;
        this.body = cached.body;
        if (this.open) {
          this.renderGLFM();
        }
      } else {
        this.loading = true;
        const { body, title, hasFetchError } = await getRenderedMarkdown(this.documentPath);
        this.title = title;
        this.body = body;
        this.loading = false;
        this.hasFetchError = hasFetchError;
        if (this.open) {
          this.renderGLFM();
        }
        cache[this.documentPath] = { title, body };
      }
    },
    getDrawerTop() {
      this.drawerTop = `${contentTop()}px`;
    },
    renderGLFM() {
      this.$nextTick(() => {
        renderGFM(this.$refs['content-element']);
      });
    },
    closeDrawer() {
      this.open = false;
    },
    toggleDrawer() {
      this.getDrawerTop();
      this.open = !this.open;
    },
    openDrawer() {
      this.getDrawerTop();
      this.open = true;
    },
  },
  safeHtmlConfig: {
    ADD_TAGS: ['copy-code'],
  },
  DRAWER_Z_INDEX,
};
</script>
<template>
  <gl-drawer
    :header-height="drawerTop"
    :open="open"
    header-sticky
    :z-index="$options.DRAWER_Z_INDEX"
    @close="closeDrawer"
  >
    <template #title>
      <h4 data-testid="title-element" class="gl-m-0">{{ title }}</h4>
    </template>
    <template #default>
      <div v-if="hasFetchError">
        <gl-alert :dismissible="false" variant="danger">{{ $options.i18n.alert }}</gl-alert>
      </div>
      <gl-skeleton-loader v-else-if="loading" />
      <div
        v-else
        ref="content-element"
        v-safe-html:[$options.safeHtmlConfig]="body"
        class="md"
      ></div>
    </template>
  </gl-drawer>
</template>
