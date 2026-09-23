<script>
import { pick } from 'lodash-es';
import { sha256 } from '~/lib/utils/text_utility';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { InternalEvents } from '~/tracking';
import {
  AGGREGATED_AUTO_PAGE_SIZE,
  DEFAULT_PAGE_SIZE,
  DEFAULT_DISPLAY_TYPE,
  EXECUTION_QUEUE_DEFAULT,
  MAX_AUTO_PAGINATED_ROWS,
  MODE_ANALYTICS,
  PAGINATION_AUTO,
  PAGINATION_BY_DISPLAY_TYPE,
  PAGINATION_LOAD_MORE,
} from '~/glql/constants';
import { parse } from '../../core/parser';
import { execute } from '../../core/executor';
import { transform } from '../../core/transformer';
import DataPresenter from '../presenters/data.vue';
import GlqlPagination from './pagination.vue';

// No display type maps to this: it is what `pagination` falls back to when neither
// strategy applies, for an aggregated display outside analytics mode or one with a `limit:`.
const PAGINATION_NONE = 'none';

export default {
  name: 'GlqlResolver',
  components: {
    DataPresenter,
    GlqlPagination,
  },
  mixins: [InternalEvents.mixin()],
  props: {
    glqlQuery: {
      required: true,
      type: String,
    },
    trackingEventName: {
      required: false,
      type: String,
      default: '',
    },
    /**
     * Namespace to compile the query against, as `{ group }` or `{ project }`.
     * When null, the namespace is derived from the current URL.
     */
    scope: {
      required: false,
      type: Object,
      default: null,
    },
    /**
     * Comparison settings: `query` is a second query run alongside `glqlQuery`, with its
     * result exposed as `comparisonData`, and `metric` names the metric used for comparison.
     * Only dashboard panels set this.
     */
    comparison: {
      required: false,
      type: Object,
      default: null,
    },
    /**
     * Request queue the queries run on. Resolvers on a page that name the same queue share
     * its concurrency limit, so dashboard panels use their own to load side by side.
     */
    queue: {
      required: false,
      type: String,
      default: EXECUTION_QUEUE_DEFAULT,
    },
  },
  emits: ['change'],
  data() {
    return {
      loading: false,

      data: undefined,
      comparisonData: undefined,
      query: undefined,
      config: undefined,
      variables: undefined,
      fields: undefined,
      mode: undefined,
      source: undefined,
      error: undefined,
      resultsTruncated: false,

      // The pagination loop is a plain async function, so destroying the component does not
      // stop it. Parents remount this component instead of mutating its props.
      discarded: false,
    };
  },
  computed: {
    hasDisplayType() {
      return Boolean(this.config?.display);
    },
    pagination() {
      const strategy = PAGINATION_BY_DISPLAY_TYPE[this.config?.display ?? DEFAULT_DISPLAY_TYPE];

      if (strategy === PAGINATION_LOAD_MORE) return PAGINATION_LOAD_MORE;
      if (
        strategy === PAGINATION_AUTO &&
        this.mode === MODE_ANALYTICS &&
        this.config?.limit == null
      ) {
        return PAGINATION_AUTO;
      }

      return PAGINATION_NONE;
    },
    hasNextPage() {
      return (
        this.pagination === PAGINATION_LOAD_MORE &&
        Boolean(this.data?.count && this.data.nodes?.length < this.data.count)
      );
    },
  },
  created() {
    // Not reactive: aborting it drops this instance's requests still waiting in the queue.
    this.abortController = new AbortController();
  },
  mounted() {
    this.executeQuery();
  },
  beforeDestroy() {
    this.discarded = true;
    this.abortController.abort();
  },
  methods: {
    resetData() {
      this.data = undefined;
      this.comparisonData = undefined;
      this.query = undefined;
      this.config = undefined;
      this.variables = undefined;
      this.fields = undefined;
      this.mode = undefined;
      this.source = undefined;
      this.error = undefined;
      this.resultsTruncated = false;
    },

    emitChange() {
      this.$emit(
        'change',
        pick(this, [
          'query',
          'data',
          'comparisonData',
          'config',
          'variables',
          'fields',
          'mode',
          'source',
          'error',
          'loading',
          'hasNextPage',
          'resultsTruncated',
        ]),
      );
    },

    setVariable(key, value) {
      if (this.variables?.[key]) {
        this.variables[key].value = value;
      }
    },

    async executeQuery() {
      if (!this.glqlQuery.trim()) return;

      this.resetData();

      this.loading = true;
      this.emitChange();

      try {
        const { query, config, variables, fields, mode, source } = await parse(
          this.glqlQuery,
          this.scope,
        );

        this.query = query;
        this.config = config;
        this.variables = variables;
        this.fields = fields;
        this.mode = mode;
        this.source = source;

        // Honor an explicit `limit:` from the user. Otherwise, paginated display
        // types (lists, tables) get the default page size; aggregated displays
        // (charts) take a full page that `autoPaginate` walks to the end of.
        if (this.config.limit != null) {
          this.setVariable('limit', this.config.limit);
        } else if (this.pagination === PAGINATION_LOAD_MORE) {
          this.setVariable('limit', DEFAULT_PAGE_SIZE);
        } else if (this.pagination === PAGINATION_AUTO) {
          this.setVariable('limit', AGGREGATED_AUTO_PAGE_SIZE);
        }

        // Started before the comparison, so the main query is queued first, and awaited only once
        // the comparison is underway, so both run at once.
        const mainRequest = execute(query, variables, {
          queue: this.queue,
          signal: this.abortController.signal,
        });
        const comparisonRequest = this.fetchComparison();
        const executionResult = await mainRequest;

        this.data = await transform(executionResult, { fields, mode, source });

        if (this.pagination === PAGINATION_AUTO) await this.autoPaginate();

        const comparisonData = await comparisonRequest;
        this.comparisonData =
          this.data?.count > AGGREGATED_AUTO_PAGE_SIZE ? undefined : comparisonData;

        this.trackRender();
      } catch (error) {
        // Keep the parsed config through the failure: consumers size their error
        // states by the display type, which the query still declares.
        const { config } = this;

        this.resetData();
        this.config = config;
        this.error = error;
      } finally {
        this.loading = false;
        this.emitChange();
      }
    },

    // Runs once, as a single page, alongside the main query. The previous period is a different
    // result set with its own rows, order and count, so it cannot be paged in step with the main
    // query; presenters pair the two by dimension identity instead. That pairing is only sound
    // when both sides are complete, so `executeQuery` discards the comparison once the main result
    // exceeds one page. The comparison request has already run by then, because the page count
    // isn't known until the main query finishes. Never rejects: a comparison that fails to
    // compile or run is reported and dropped, so the main result still renders without it.
    async fetchComparison() {
      if (!this.comparison?.query) return undefined;

      try {
        const { query, variables, fields, mode, source } = await parse(
          this.comparison.query,
          this.scope,
        );
        const executionResult = await execute(query, variables, {
          queue: this.queue,
          signal: this.abortController.signal,
        });
        const result = await transform(executionResult, { fields, mode, source });

        return { ...result, metric: this.comparison.metric };
      } catch (error) {
        // Skip only the queue's own abort rejection, so real failures after teardown still report.
        if (error === this.abortController.signal.reason) return undefined;

        Sentry.captureException(error);
        return undefined;
      }
    },

    async fetchNextPage() {
      const executionResult = await execute(this.query, this.variables, {
        queue: this.queue,
        signal: this.abortController.signal,
      });

      const data = await transform(executionResult, {
        fields: this.fields,
        mode: this.mode,
        source: this.source,
      });

      this.data = {
        ...this.data,
        pageInfo: data.pageInfo,
        nodes: [...this.data.nodes, ...data.nodes],
      };
    },

    // Emits nothing: the caller emits once, so the chart never draws a partial aggregate.
    async autoPaginate() {
      if (!this.data?.nodes) return;

      // Bounds requests as well as rows, so a backend that keeps claiming another page can't spin.
      const maxPages = Math.ceil(MAX_AUTO_PAGINATED_ROWS / AGGREGATED_AUTO_PAGE_SIZE);

      for (let page = 0; page < maxPages; page += 1) {
        if (this.discarded) return;

        const after = this.data.pageInfo?.endCursor;
        if (!after || !this.data.pageInfo.hasNextPage) break;
        if (this.data.nodes.length >= MAX_AUTO_PAGINATED_ROWS) break;

        this.setVariable('after', after);

        try {
          // Sequential by nature: each request needs the previous page's cursor.
          // eslint-disable-next-line no-await-in-loop
          await this.fetchNextPage();
        } catch (error) {
          if (this.discarded) return;

          // Rate limiting is keyed by query SHA, so once a page fails the next is rejected too.
          // Keep the pages already loaded rather than losing the chart. TODO: warn that the view
          // is incomplete — https://gitlab.com/gitlab-org/glql/-/work_items/216
          Sentry.captureException(error);
          break;
        }
      }

      // Every exit above can leave rows behind, not just the row cap: a short page, a missing
      // cursor, or a failed continuation. Compare against the total rather than track each one.
      this.resultsTruncated = Boolean(this.data?.count && this.data.nodes.length < this.data.count);
    },

    async loadMore() {
      try {
        this.setVariable('after', this.data.pageInfo?.endCursor);
        this.loading = true;
        this.emitChange();

        await this.fetchNextPage();
      } catch (error) {
        this.error = error;
      } finally {
        this.loading = false;
        this.emitChange();
      }
    },

    async trackRender() {
      if (!this.trackingEventName) return;

      try {
        this.trackEvent(this.trackingEventName, { label: await sha256(this.glqlQuery) });
      } catch (e) {
        // ignore any tracking errors
      }
    },

    handlePresenterError(error) {
      // The presenter cannot render these rows, so there is nothing worth keeping on screen.
      this.data = undefined;
      this.error = error;
      this.emitChange();
    },
  },
};
</script>
<template>
  <div>
    <!-- An error with rows already loaded (a failed continuation page) keeps them visible. -->
    <data-presenter
      v-if="hasDisplayType && (data || !error)"
      :data="data"
      :comparison-data="comparisonData"
      :fields="fields"
      :display-type="config.display"
      :display-config="config.displayConfig"
      :source="source"
      :loading="loading"
      @error="handlePresenterError"
    />
    <div v-if="hasNextPage" class="glql-load-more gl-border-t gl-p-3">
      <glql-pagination
        :count="data.nodes.length"
        :total-count="data.count"
        :page-size="variables.limit.value"
        :loading="loading"
        @load-more="loadMore"
      />
    </div>
  </div>
</template>
