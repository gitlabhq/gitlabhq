<script>
import { GlAlert, GlButton, GlModal, GlIntersectionObserver, GlSkeletonLoader } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { __, sprintf } from '~/locale';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { renderMarkdown } from '~/notes/utils';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { InternalEvents } from '~/tracking';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
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
      crudComponentId: `glql-${this.queryKey}`,

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
      itemsCount: null,
      retryCount: 0,
      showResolver: false,

      query: undefined,
      config: undefined,
      data: undefined,

      preClasses: 'code highlight code-syntax-highlight-theme',

      isCollapsed: false,
    };
  },
  computed: {
    title() {
      if (this.config?.title) return this.config.title;
      if (this.loading) return '';

      return this.config?.display === 'table'
        ? __('Embedded table view')
        : __('Embedded list view');
    },
    description() {
      return this.config?.description;
    },
    showEmptyState() {
      return this.data?.nodes?.length === 0;
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
    onResolverChange({ loading, query, config, data, aggregate, groupBy, error }) {
      this.loading = loading;
      this.query = query;
      this.config = config;
      this.data = data;
      this.itemsCount = aggregate?.length && groupBy?.length ? null : data?.count;

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
  <div data-testid="glql-facade">
    <template v-if="hasError">
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
        :anchor-id="crudComponentId"
        :title="title"
        :description="description"
        :count="itemsCount"
        is-collapsible
        :collapsed="isCollapsed"
        keep-alive-collapsed-content
        :show-zero-count="!loading"
        persist-collapsed-state
        class="!gl-mt-5"
        :body-class="{
          '!gl-m-0 !gl-p-0': loading || (data && data.count),
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
            @viewSource="viewSource"
            @copySource="copySource"
            @copyAsGFM="copyAsGFM"
            @reload="reload"
          />
        </template>

        <glql-resolver
          v-if="showResolver"
          ref="resolver"
          :key="retryCount"
          :glql-query="queryYaml"
          @change="onResolverChange"
        />

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
