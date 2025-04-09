<script>
import { GlAlert, GlButton, GlModal, GlIntersectionObserver } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { renderMarkdown } from '~/notes/utils';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { InternalEvents } from '~/tracking';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { copyGLQLNodeAsGFM } from '../../utils/copy_as_gfm';
import { executeAndPresentQuery, presentPreview } from '../../core';
import Counter from '../../utils/counter';
import { eventHubByKey } from '../../utils/event_hub_factory';

const MAX_GLQL_BLOCKS = 20;

export default {
  name: 'GlqlFacade',
  components: {
    GlAlert,
    GlButton,
    GlModal,
    GlIntersectionObserver,
  },
  directives: {
    SafeHtml,
  },
  mixins: [InternalEvents.mixin(), glFeatureFlagsMixin()],
  inject: ['queryKey'],
  props: {
    query: {
      required: true,
      type: String,
    },
  },
  data() {
    return {
      eventHub: eventHubByKey(this.queryKey),

      queryModalSettings: {
        id: `glql-${this.queryKey}`,
        show: false,
        title: '',
        primaryAction: { text: __('Copy source') },
        cancelAction: { text: __('Close') },
      },

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
    wrappedQuery() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `\`\`\`glql\n${this.query}\n\`\`\``;
    },
  },
  async mounted() {
    this.loadOnClick = this.glFeatures.glqlLoadOnClick;

    this.eventHub.$on('dropdownAction', this.onDropdownAction.bind(this));
  },

  methods: {
    onDropdownAction(action, ...data) {
      if (typeof this[action] === 'function') this[action](...data);
    },

    viewSource({ title }) {
      Object.assign(this.queryModalSettings, { title, show: true });
    },

    copySource() {
      navigator.clipboard.writeText(this.wrappedQuery);
    },

    async copyAsGFM() {
      await copyGLQLNodeAsGFM(this.$refs.presenter.$el);
    },

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
        this.presenterComponent = await executeAndPresentQuery(this.query, this.queryKey);
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
        this.presenterPreview = await presentPreview(this.query, this.queryKey);
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
        this.trackEvent('render_glql_block', { label: this.queryKey });
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
      >{{ $options.i18n.loadGlqlView }}</gl-button><code class="gl-opacity-2">{{ query }}</code></pre>
    </div>
    <gl-intersection-observer v-else @appear="loadGlqlBlock">
      <component :is="presenterComponent" v-if="presenterComponent" ref="presenter" />
      <component :is="presenterPreview" v-else-if="presenterPreview && !hasError" />
      <div v-else-if="hasError" class="markdown-code-block gl-relative">
        <pre :class="preClasses"><code>{{ query }}</code></pre>
      </div>
    </gl-intersection-observer>
    <gl-modal
      v-model="queryModalSettings.show"
      :title="queryModalSettings.title"
      :modal-id="queryModalSettings.id"
      :action-primary="queryModalSettings.primaryAction"
      :action-cancel="queryModalSettings.cancelAction"
      @primary="copySource"
    >
      <div class="md">
        <div class="markdown-code-block gl-relative">
          <pre :class="preClasses"><code>{{ wrappedQuery }}</code></pre>
        </div>
      </div>
    </gl-modal>
  </div>
</template>
