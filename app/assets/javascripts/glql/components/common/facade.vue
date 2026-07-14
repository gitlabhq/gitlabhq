<script>
import { GlAlert, GlButton, GlModal, GlIntersectionObserver, GlSkeletonLoader } from '@gitlab/ui';
import { uniqueId } from 'lodash-es';
import { __, sprintf } from '~/locale';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { renderMarkdown } from '~/notes/utils';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { InternalEvents } from '~/tracking';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { MODE_ANALYTICS, FULL_BLEED_DISPLAY_TYPES } from '../../constants';
import { copyGLQLNodeAsGFM } from '../../utils/copy_as_gfm';
import Counter from '../../utils/counter';
import GlqlResolver from './resolver.vue';
import GlqlActions from './actions.vue';
import GlqlFootnote from './footnote.vue';

const MAX_GLQL_BLOCKS = 20;

export default {
  name: 'GlqlFacade',
  components: {
    GlAlert,
    GlButton,
    GlModal,
    GlIntersectionObserver,
    GlSkeletonLoader,
    CrudComponent,
    GlqlResolver,
    GlqlFootnote,
    GlqlActions,
  },
  directives: {
    SafeHtml,
  },
  mixins: [InternalEvents.mixin(), glFeatureFlagsMixin()],
  props: {
    // eslint-disable-next-line vue/no-unused-properties -- queryKey is passed from index.js, keeping for potential future use
    queryKey: {
      required: true,
      type: String,
    },
    queryYaml: {
      required: true,
      type: String,
    },
  },
  data() {
    return {
      queryModalSettings: {
        id: uniqueId('glql-modal-'),
        show: false,
        title: '',
        primaryAction: { text: __('Copy source') },
        cancelAction: { text: __('Close') },
      },

      error: {
        variant: 'warning',
        title: null,
        message: null,
        action: null,
      },

      loading: false,
      retryCount: 0,
      showResolver: false,

      query: undefined,
      config: undefined,
      data: undefined,
      mode: undefined,

      preClasses: 'code highlight code-syntax-highlight-theme',

      isCollapsed: false,
    };
  },
  computed: {
    title() {
      if (this.config?.title) return this.config.title;
      if (this.loading) return '';

      return __('Embedded view');
    },
    description() {
      return this.config?.description;
    },
    isAnalyticsMode() {
      return this.mode === MODE_ANALYTICS;
    },
    itemsCount() {
      // Analytics mode aggregates results into dimensions and metrics, so a row
      // count is meaningless there. Only show the count for standard, per-item results.
      return this.isAnalyticsMode ? null : this.data?.count;
    },
    showZeroCount() {
      // A zero count is only meaningful for standard, per-item results.
      return !this.loading && !this.isAnalyticsMode;
    },
    showEmptyState() {
      return this.data?.nodes?.length === 0;
    },
    isInsetDisplay() {
      // Full-bleed displays (list/table) render edge-to-edge; every other display
      // gets its inset from the card here, so presenters can render flush.
      return this.config?.display && !FULL_BLEED_DISPLAY_TYPES.has(this.config.display);
    },
    showCopyContentsAction() {
      return Boolean(this.data?.count) && !this.isCollapsed;
    },
    hasError() {
      return this.error.title || this.error.message;
    },
    wrappedQuery() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `\`\`\`glql\n${this.queryYaml}\n\`\`\``;
    },
    loadOnClick() {
      return this.glFeatures.glqlLoadOnClick;
    },
    showLoadBtn() {
      return this.loadOnClick && !this.showResolver;
    },
  },
  watch: {
    config() {
      this.isCollapsed = this.config?.collapsed || false;
    },
  },
  methods: {
    viewSource({ title }) {
      Object.assign(this.queryModalSettings, { title, show: true });
    },

    copySource() {
      // eslint-disable-next-line no-restricted-properties
      navigator.clipboard.writeText(this.wrappedQuery);
    },

    reload() {
      this.data = undefined;
      this.showResolver = true;
      this.retryCount += 1;
      this.error = {};
    },

    async copyAsGFM() {
      await copyGLQLNodeAsGFM(this.$refs.resolver.$el);
    },

    onAppear() {
      this.showResolver = this.showResolver || this.checkGlqlBlocksCount();
    },

    checkGlqlBlocksCount() {
      // When forcing load on click, don't bother checking the number of GLQL blocks loaded.
      if (this.loadOnClick) return false;

      try {
        this.$options.numGlqlBlocks.increment();
        return true;
      } catch (e) {
        this.error = {
          variant: 'warning',
          title: sprintf(
            __(
              'Only %{n} embedded views can be automatically displayed on a page. Click the button below to manually display this view.',
            ),
            { n: MAX_GLQL_BLOCKS },
          ),
          action: __('Display view'),
        };
        return false;
      }
    },
    renderMarkdown,
    onResolverChange({ loading, query, config, data, mode, error }) {
      this.loading = loading;
      this.query = query;
      this.config = config;
      this.data = data;
      this.mode = mode;

      if (error) {
        this.handleError(error);
      }
    },
    handleError(error) {
      switch (error.networkError?.statusCode) {
        case 503:
          this.error = {
            variant: 'warning',
            title: __('Embedded view timed out. Add more filters to reduce the number of results.'),
            action: __('Retry'),
          };
          break;
        case 403:
          this.error = {
            variant: 'danger',
            title: __('You do not have permission to view this embedded view.'),
          };
          break;
        default:
          this.error = {
            variant: 'warning',
            title: __('An error occurred when trying to display this embedded view:'),
            message: error.message,
          };
      }
    },
  },
  safeHtmlConfig: { ALLOWED_TAGS: ['code'] },
  i18n: {
    loadGlqlView: __('Load embedded view'),
  },
  numGlqlBlocks: new Counter(MAX_GLQL_BLOCKS),
};
</script>
<template>
  <div data-testid="glql-facade" class="gl-min-w-0 gl-grow">
    <template v-if="hasError">
      <!-- eslint-disable vue/v-on-event-hyphenation -- GlAlert emits the camelCase `primaryAction` event. -->
      <gl-alert
        :variant="error.variant"
        class="!gl-my-3"
        :dismissible="false"
        :primary-button-text="error.action"
        @primaryAction="reload"
      >
        {{ error.title }}
        <ul v-if="error.message" class="!gl-mb-0">
          <li v-safe-html:[$options.safeHtmlConfig]="renderMarkdown(error.message)"></li>
        </ul>
      </gl-alert>
      <!-- eslint-enable vue/v-on-event-hyphenation -->
    </template>

    <div v-if="hasError || showLoadBtn" class="markdown-code-block gl-relative">
      <pre :class="preClasses"><gl-button
        v-if="showLoadBtn"
        class="gl-font-regular gl-absolute gl-z-1 gl-top-2/4 gl-left-2/4"
        style="transform: translate(-50%, -50%)"
        :aria-label="$options.i18n.loadGlqlView"
        @click="showResolver = true"
      >{{ $options.i18n.loadGlqlView }}</gl-button><code :class="{ 'gl-opacity-2': showLoadBtn }">{{ queryYaml }}</code></pre>
    </div>
    <gl-intersection-observer v-else @appear.once="onAppear">
      <crud-component
        :title="title"
        :description="description"
        :count="itemsCount"
        is-collapsible
        :collapsed="isCollapsed"
        :show-zero-count="showZeroCount"
        class="!gl-mt-5"
        :body-class="{
          '!gl-m-0 !gl-p-0': data && data.count,
          '!gl-overflow-hidden': true,
        }"
        @collapsed="isCollapsed = true"
        @expanded="isCollapsed = false"
      >
        <template v-if="!title" #title>
          <div data-testid="title-skeleton-loader">
            <gl-skeleton-loader :lines="1" />
          </div>
        </template>

        <template #actions>
          <glql-actions
            :show-copy-contents="showCopyContentsAction"
            :modal-title="title"
            @view-source="viewSource"
            @copy-source="copySource"
            @copy-as-gfm="copyAsGFM"
            @reload="reload"
          />
        </template>

        <div :class="{ 'gl-px-5 gl-py-5': isInsetDisplay }" data-testid="glql-content">
          <glql-resolver
            v-if="showResolver"
            ref="resolver"
            :key="retryCount"
            :glql-query="queryYaml"
            tracking-event-name="render_glql_block"
            @change="onResolverChange"
          />
        </div>

        <template v-if="showEmptyState" #empty>
          {{ __('No data found for this query.') }}
        </template>
      </crud-component>
      <glql-footnote v-if="!isCollapsed" />
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
