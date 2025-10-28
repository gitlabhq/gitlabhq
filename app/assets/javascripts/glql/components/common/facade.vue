<script>
import { GlAlert, GlButton, GlModal, GlIntersectionObserver } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { __, sprintf } from '~/locale';
import { sha256 } from '~/lib/utils/text_utility';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { renderMarkdown } from '~/notes/utils';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { InternalEvents } from '~/tracking';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { parse } from '../../core/parser';
import { execute } from '../../core/executor';
import { transform } from '../../core/transformer';
import DataPresenter from '../presenters/data.vue';
import { copyGLQLNodeAsGFM } from '../../utils/copy_as_gfm';
import Counter from '../../utils/counter';
import GlqlPagination from './pagination.vue';
import GlqlActions from './actions.vue';
import GlqlFootnote from './footnote.vue';

const MAX_GLQL_BLOCKS = 20;
const DEFAULT_PAGE_SIZE = 20;

export default {
  name: 'GlqlFacade',
  components: {
    GlAlert,
    GlButton,
    GlModal,
    GlIntersectionObserver,
    CrudComponent,
    GlqlPagination,
    GlqlFootnote,
    GlqlActions,
    DataPresenter,
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

      loadOnClick: true,
      error: {
        variant: 'warning',
        title: null,
        message: null,
        action: null,
      },

      loading: false,

      query: undefined,
      config: undefined,
      variables: undefined,
      fields: undefined,
      aggregate: undefined,
      groupBy: undefined,
      data: undefined,

      preClasses: 'code highlight code-syntax-highlight-theme',

      isCollapsed: false,
    };
  },
  computed: {
    title() {
      return (
        this.config.title ||
        (this.config.display === 'table' ? __('Embedded table view') : __('Embedded list view'))
      );
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
    itemsCount() {
      if (this.aggregate?.length && this.groupBy?.length) return null;
      return this.data?.count;
    },
  },
  watch: {
    config() {
      this.isCollapsed = this.config?.collapsed || false;
    },
  },
  async mounted() {
    this.loadOnClick = this.glFeatures.glqlLoadOnClick;
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

    setVariable(key, value) {
      if (this.variables[key]) {
        this.variables[key].value = value;
      }
    },

    async loadMore(count) {
      try {
        this.loading = count;

        this.setVariable('after', this.data.pageInfo.endCursor);
        this.setVariable('limit', DEFAULT_PAGE_SIZE);

        const data = await transform(await execute(this.query, this.variables), this.config);
        this.data = {
          ...this.data,
          pageInfo: data.pageInfo,
          nodes: [...this.data.nodes, ...data.nodes],
        };
      } catch {
        this.handleQueryError(__('Unable to load the next page.'));
      } finally {
        this.loading = false;
      }
    },

    async loadGlqlBlock() {
      await this.parseQuery();
      if (!this.hasError && (this.glFeatures.glqlLoadOnClick || this.checkGlqlBlocksCount())) {
        await this.executeQuery();
      }
    },

    reloadGlqlBlock() {
      this.data = undefined;
      this.dismissAlert();
      return this.executeQuery();
    },

    async executeQuery() {
      try {
        if (this.hasError) return;

        this.loading = true;
        this.setVariable('limit', this.config.limit);
        this.data = await transform(await execute(this.query, this.variables), this.config);

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
      } finally {
        this.loading = false;
      }
    },

    async parseQuery() {
      try {
        const { query, config, variables, fields, aggregate, groupBy } = await parse(
          this.queryYaml,
        );
        this.query = query;
        this.config = config;
        this.variables = variables;
        this.fields = fields;
        this.aggregate = aggregate;
        this.groupBy = groupBy;
        this.loading = true;
      } catch (error) {
        this.handleQueryError(error.message);
        this.loading = false;
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
        this.trackEvent('render_glql_block', { label: await sha256(this.queryYaml) });
      } catch (e) {
        // ignore any tracking errors
      }
    },
    onPresenterError(error) {
      this.error = {
        variant: 'warning',
        title: error,
        message: null,
        action: null,
      };
    },
  },
  safeHtmlConfig: { ALLOWED_TAGS: ['code'] },
  i18n: {
    glqlDisplayError: {
      variant: 'warning',
      title: __('An error occurred when trying to display this embedded view:'),
    },
    glqlLimitError: {
      variant: 'warning',
      title: sprintf(
        __(
          'Only %{n} embedded views can be automatically displayed on a page. Click the button below to manually display this view.',
        ),
        { n: MAX_GLQL_BLOCKS },
      ),
      action: __('Display view'),
    },
    glqlTimeoutError: {
      variant: 'warning',
      title: sprintf(
        __('Embedded view timed out. Add more filters to reduce the number of results.'),
        {
          n: MAX_GLQL_BLOCKS,
        },
      ),
      action: __('Retry'),
    },
    glqlForbiddenError: {
      variant: 'danger',
      title: __('Embedded view timed out. Try again later.'),
    },
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
      >{{ $options.i18n.loadGlqlView }}</gl-button><code class="gl-opacity-2">{{ queryYaml }}</code></pre>
    </div>
    <gl-intersection-observer v-else @appear.once="loadGlqlBlock">
      <template v-if="query && !hasError">
        <crud-component
          :anchor-id="crudComponentId"
          :title="title"
          :description="config.description"
          :count="itemsCount"
          is-collapsible
          :collapsed="isCollapsed"
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

          <data-presenter
            ref="presenter"
            :data="data"
            :fields="fields"
            :aggregate="aggregate"
            :group-by="groupBy"
            :display-type="config.display"
            :loading="loading"
            @error="onPresenterError"
          />
          <div
            v-if="data && data.count && data.nodes.length < data.count"
            class="glql-load-more gl-border-t gl-border-section gl-p-3"
          >
            <glql-pagination
              :count="data.nodes.length"
              :total-count="data.count"
              :loading="loading"
              @loadMore="loadMore"
            />
          </div>

          <template v-if="showEmptyState" #empty>
            {{ __('No data found for this query.') }}
          </template>
        </crud-component>
        <glql-footnote v-if="!isCollapsed" />
      </template>
      <div v-else class="markdown-code-block gl-relative">
        <pre :class="preClasses"><code>{{ queryYaml }}</code></pre>
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
