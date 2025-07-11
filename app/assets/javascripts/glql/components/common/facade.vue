<script>
import {
  GlAlert,
  GlButton,
  GlModal,
  GlIntersectionObserver,
  GlIcon,
  GlLink,
  GlSprintf,
  GlExperimentBadge,
} from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { renderMarkdown } from '~/notes/utils';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { InternalEvents } from '~/tracking';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { copyGLQLNodeAsGFM } from '../../utils/copy_as_gfm';
import { executeAndPresentQuery, presentPreview, loadMore } from '../../core';
import Counter from '../../utils/counter';
import { eventHubByKey } from '../../utils/event_hub_factory';
import GlqlFooter from './footer.vue';
import GlqlActions from './actions.vue';
import GlqlFootnote from './footnote.vue';

const MAX_GLQL_BLOCKS = 20;

export default {
  name: 'GlqlFacade',
  components: {
    GlAlert,
    GlButton,
    GlModal,
    GlIcon,
    GlLink,
    GlSprintf,
    GlExperimentBadge,
    GlIntersectionObserver,
    CrudComponent,
    GlqlFooter,
    GlqlFootnote,
    GlqlActions,
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
      previewPresenter: null,
      finalPresenter: null,
      error: {
        variant: 'warning',
        title: null,
        message: null,
        action: null,
      },

      preClasses: 'code highlight code-syntax-highlight-theme',

      isCollapsed: false,
    };
  },
  computed: {
    data() {
      return this.finalPresenter?.data || {};
    },
    config() {
      return this.finalPresenter?.config || this.previewPresenter?.config || {};
    },
    isPreview() {
      return !this.finalPresenter;
    },
    title() {
      return (
        this.config.title || (this.config.display === 'table' ? __('GLQL table') : __('GLQL list'))
      );
    },
    showEmptyState() {
      return this.data.nodes?.length === 0 && !this.isPreview;
    },
    showCopyContentsAction() {
      return Boolean(this.data.count) && !this.isCollapsed && !this.isPreview;
    },
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

    this.eventHub.$on('viewSource', this.viewSource.bind(this));
    this.eventHub.$on('copySource', this.copySource.bind(this));
    this.eventHub.$on('copyAsGFM', this.copyAsGFM.bind(this));
    this.eventHub.$on('reload', this.reload.bind(this));
    this.eventHub.$on('loadMore', this.loadMore.bind(this));
  },

  methods: {
    viewSource({ title }) {
      Object.assign(this.queryModalSettings, { title, show: true });
    },

    copySource() {
      navigator.clipboard.writeText(this.wrappedQuery);
    },

    reload() {
      this.reloadGlqlBlock();
    },

    async copyAsGFM() {
      await copyGLQLNodeAsGFM(this.$refs.presenter.$el);
    },

    async loadMore() {
      try {
        const data = await loadMore(this.query, this.data.pageInfo.endCursor);
        this.finalPresenter.data.pageInfo = data.pageInfo;
        this.finalPresenter.data.nodes.push(...data.nodes);

        this.eventHub.$emit('loadMoreComplete', this.finalPresenter.data);
      } catch (error) {
        this.handleQueryError(__('Unable to load the next page.'));
        this.eventHub.$emit('loadMoreError');
      }
    },

    loadGlqlBlock() {
      if (this.finalPresenter || this.previewPresenter) return;

      if (this.glFeatures.glqlLoadOnClick || this.checkGlqlBlocksCount()) {
        this.loadPreviewPresenter();
        this.loadFinalPresenter();
      }
    },

    reloadGlqlBlock() {
      this.finalPresenter = null;
      this.previewPresenter = null;

      this.dismissAlert();
      this.loadPreviewPresenter();
      this.loadFinalPresenter();
    },

    async loadFinalPresenter() {
      try {
        this.finalPresenter = await executeAndPresentQuery(this.query, this.queryKey);
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

    async loadPreviewPresenter() {
      this.dismissAlert();

      try {
        this.previewPresenter = await presentPreview(this.query, this.queryKey);
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
        class="!gl-my-3"
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
      <template v-if="finalPresenter || previewPresenter">
        <crud-component
          :anchor-id="queryKey"
          :title="title"
          :description="config.description"
          :count="data.count"
          is-collapsible
          persist-collapsed-state
          class="!gl-mt-5"
          :body-class="{ '!gl-m-0 !gl-p-0': data.count || isPreview }"
          @collapsed="isCollapsed = true"
          @expanded="isCollapsed = false"
        >
          <template #actions>
            <glql-actions :show-copy-contents="showCopyContentsAction" :modal-title="title" />
          </template>

          <component :is="finalPresenter.component" v-if="finalPresenter" ref="presenter" />
          <component :is="previewPresenter.component" v-else-if="previewPresenter && !hasError" />
          <div
            v-if="data.count && data.nodes.length < data.count"
            class="gl-border-t gl-border-section gl-p-3"
          >
            <glql-footer :count="data.nodes.length" :total-count="data.count" />
          </div>

          <template v-if="showEmptyState" #empty>
            {{ __('No data found for this query.') }}
          </template>

          <template #footer>
            <glql-footnote />
          </template>
        </crud-component>
      </template>
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
