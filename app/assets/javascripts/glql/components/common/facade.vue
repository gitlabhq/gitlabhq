<script>
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { renderMarkdown } from '~/notes/utils';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { sha256 } from '~/lib/utils/text_utility';
import { InternalEvents } from '~/tracking';
import { executeAndPresentQuery } from '../../core';
import Counter from '../../utils/counter';

const MAX_GLQL_BLOCKS = 20;

export default {
  name: 'GlqlFacade',
  components: {
    GlAlert,
    GlLoadingIcon,
  },
  directives: {
    SafeHtml,
  },
  mixins: [InternalEvents.mixin()],
  props: {
    query: {
      required: true,
      type: String,
    },
  },
  data() {
    return {
      presenterComponent: null,
      loading: false,
      error: {
        title: null,
        message: null,
        action: null,
      },

      // eslint-disable-next-line @gitlab/require-i18n-strings
      preClasses: `code highlight ${gon.user_color_scheme}`,
    };
  },
  async mounted() {
    if (this.checkGlqlBlocks()) {
      this.presentQuery();
    }
  },
  methods: {
    setLoading(loading) {
      this.$emit(loading ? 'loading' : 'loaded');
      this.loading = loading;
    },
    checkGlqlBlocks() {
      try {
        this.$options.numGlqlBlocks.increment();
        return true;
      } catch (e) {
        this.handleLimitError();
        return false;
      }
    },
    async presentQuery() {
      this.dismissAlert();
      this.setLoading(true);

      try {
        this.presenterComponent = await executeAndPresentQuery(this.query);
        this.trackRender();
      } catch (error) {
        this.handleQueryError(error.message);
      } finally {
        this.setLoading(false);
      }
    },
    handleQueryError(message) {
      this.error = { ...this.$options.i18n.glqlDisplayError, message };
    },
    handleLimitError() {
      this.error = this.$options.i18n.glqlLimitError;
    },
    dismissAlert() {
      this.error = {};
    },
    renderMarkdown,
    async trackRender() {
      try {
        this.trackEvent('render_glql_block', { label: await sha256(this.query) });
      } catch (e) {
        // ignore any tracking errors
      }
    },
  },
  safeHtmlConfig: { ALLOWED_TAGS: ['code'] },
  i18n: {
    glqlDisplayError: {
      title: __('An error occurred when trying to display this GLQL block:'),
    },
    glqlLimitError: {
      title: sprintf(
        __(
          'Only %{n} GLQL blocks can be automatically displayed on a page. Click the button below to manually display this block.',
        ),
        { n: MAX_GLQL_BLOCKS },
      ),
      action: __('Display block'),
    },
  },
  numGlqlBlocks: new Counter(MAX_GLQL_BLOCKS),
};
</script>
<template>
  <div data-testid="glql-facade">
    <gl-alert
      v-if="error.title || error.message"
      variant="warning"
      class="gl-mb-3"
      :primary-button-text="error.action"
      @dismiss="dismissAlert"
      @primaryAction="presentQuery"
    >
      {{ error.title }}
      <ul v-if="error.message" class="!gl-mb-0">
        <li v-safe-html:[$options.safeHtmlConfig]="renderMarkdown(error.message)"></li>
      </ul>
    </gl-alert>

    <component :is="presenterComponent" v-if="presenterComponent" />
    <div v-else class="markdown-code-block gl-relative">
      <gl-loading-icon
        v-if="loading"
        size="lg"
        class="gl-absolute gl-left-1/2 gl-top-1/2 gl-z-2 -gl-translate-x-1/2 -gl-translate-y-1/2"
      />
      <pre
        :class="preClasses"
      ><code :class="{ 'gl-opacity-5': loading }">{{ query.trim() }}</code></pre>
    </div>
  </div>
</template>
