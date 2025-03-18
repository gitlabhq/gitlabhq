<script>
import { GlAlert, GlButton, GlIntersectionObserver } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { renderMarkdown } from '~/notes/utils';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { sha256 } from '~/lib/utils/text_utility';
import { InternalEvents } from '~/tracking';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { executeAndPresentQuery, presentPreview } from '../../core';
import Counter from '../../utils/counter';

const MAX_GLQL_BLOCKS = 20;

export default {
  name: 'GlqlFacade',
  components: {
    GlAlert,
    GlButton,
    GlIntersectionObserver,
  },
  directives: {
    SafeHtml,
  },
  mixins: [InternalEvents.mixin(), glFeatureFlagsMixin()],
  props: {
    query: {
      required: true,
      type: String,
    },
  },
  data() {
    return {
      loadOnClick: true,
      presenterPreview: null,
      presenterComponent: null,
      error: {
        variant: 'warning',
        title: null,
        message: null,
        action: null,
      },

      // eslint-disable-next-line @gitlab/require-i18n-strings
      preClasses: `code highlight ${gon.user_color_scheme}`,
    };
  },
  computed: {
    hasError() {
      return this.error.title || this.error.message;
    },
  },
  async mounted() {
    this.loadOnClick = this.glFeatures.glqlLoadOnClick;
  },
  methods: {
    loadGlqlBlock() {
      if (this.presenterComponent || this.presenterPreview) return;

      if (this.glFeatures.glqlLoadOnClick || this.checkGlqlBlocksCount()) {
        this.presentPreview();
        this.loadPresenterComponent();
      }
    },

    reloadGlqlBlock() {
      this.presenterComponent = null;
      this.presenterPreview = null;

      this.dismissAlert();
      this.presentPreview();
      this.loadPresenterComponent();
    },

    async loadPresenterComponent() {
      try {
        this.presenterComponent = await executeAndPresentQuery(this.query);
        this.trackRender();
      } catch (error) {
        switch (error.networkError?.statusCode) {
          case 503:
            this.handleTimeoutError();
            break;
          case 403:
            this.handleForbiddenError();
            break;
          default:
            this.handleQueryError(error.message);
        }
      }
    },

    async presentPreview() {
      this.dismissAlert();

      try {
        this.presenterPreview = await presentPreview(this.query);
      } catch (error) {
        this.handleQueryError(error.message);
      }
    },

    checkGlqlBlocksCount() {
      try {
        this.$options.numGlqlBlocks.increment();
        return true;
      } catch (e) {
        this.handleLimitError();
        return false;
      }
    },

    handleQueryError(message) {
      this.error = { ...this.$options.i18n.glqlDisplayError, message };
    },
    handleLimitError() {
      this.error = this.$options.i18n.glqlLimitError;
    },
    handleTimeoutError() {
      this.error = this.$options.i18n.glqlTimeoutError;
    },
    handleForbiddenError() {
      this.error = this.$options.i18n.glqlForbiddenError;
    },
    dismissAlert() {
      this.error = { variant: 'warning' };
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
      variant: 'warning',
      title: __('An error occurred when trying to display this GLQL view:'),
    },
    glqlLimitError: {
      variant: 'warning',
      title: sprintf(
        __(
          'Only %{n} GLQL views can be automatically displayed on a page. Click the button below to manually display this block.',
        ),
        { n: MAX_GLQL_BLOCKS },
      ),
      action: __('Display block'),
    },
    glqlTimeoutError: {
      variant: 'warning',
      title: sprintf(__('GLQL view timed out. Add more filters to reduce the number of results.'), {
        n: MAX_GLQL_BLOCKS,
      }),
      action: __('Retry'),
    },
    glqlForbiddenError: {
      variant: 'danger',
      title: __('GLQL view timed out. Try again later.'),
    },
    loadGlqlView: __('Load GLQL view'),
  },
  numGlqlBlocks: new Counter(MAX_GLQL_BLOCKS),
};
</script>
<template>
  <div data-testid="glql-facade">
    <template v-if="hasError">
      <gl-alert
        :variant="error.variant"
        class="gl-mb-3"
        :primary-button-text="error.action"
        @dismiss="dismissAlert"
        @primaryAction="reloadGlqlBlock"
      >
        {{ error.title }}
        <ul v-if="error.message" class="!gl-mb-0">
          <li v-safe-html:[$options.safeHtmlConfig]="renderMarkdown(error.message)"></li>
        </ul>
      </gl-alert>
    </template>

    <div v-if="loadOnClick" class="markdown-code-block gl-relative">
      <pre :class="preClasses"><gl-button
        class="gl-font-regular gl-absolute gl-z-1 gl-top-2/4 gl-left-2/4"
        style="transform: translate(-50%, -50%)"
        :aria-label="$options.i18n.loadGlqlView"
        @click="loadOnClick = false"
      >{{ $options.i18n.loadGlqlView }}</gl-button><code class="gl-opacity-2">{{ query.trim() }}</code></pre>
    </div>
    <gl-intersection-observer v-else @appear="loadGlqlBlock">
      <component :is="presenterComponent" v-if="presenterComponent" />
      <component :is="presenterPreview" v-else-if="presenterPreview && !hasError" />
      <div v-else-if="hasError" class="markdown-code-block gl-relative">
        <pre :class="preClasses"><code>{{ query.trim() }}</code></pre>
      </div>
    </gl-intersection-observer>
  </div>
</template>
