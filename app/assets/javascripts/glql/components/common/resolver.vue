<script>
import { pick } from 'lodash-es';
import { sha256 } from '~/lib/utils/text_utility';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { InternalEvents } from '~/tracking';
import {
  DEFAULT_PAGE_SIZE,
  DEFAULT_DISPLAY_TYPE,
  PAGINATED_DISPLAY_TYPES_WITH_DEFAULT_LIMIT,
} from '~/glql/constants';
import { parse } from '../../core/parser';
import { execute } from '../../core/executor';
import { transform } from '../../core/transformer';
import DataPresenter from '../presenters/data.vue';
import GlqlPagination from './pagination.vue';

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
     * A second query run alongside `glqlQuery`, with its result exposed as `comparisonData`.
     */
    comparisonQuery: {
      required: false,
      type: String,
      default: '',
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
    };
  },
  computed: {
    hasDisplayType() {
      return Boolean(this.config?.display);
    },
    isPaginatedDisplayWithDefaultLimit() {
      return PAGINATED_DISPLAY_TYPES_WITH_DEFAULT_LIMIT.has(
        this.config?.display ?? DEFAULT_DISPLAY_TYPE,
      );
    },
    hasNextPage() {
      return (
        this.isPaginatedDisplayWithDefaultLimit &&
        Boolean(this.data?.count && this.data.nodes?.length < this.data.count)
      );
    },
  },
  watch: {
    glqlQuery() {
      this.executeQuery();
    },
    // The query string is unchanged when only the namespace changes, so without this the
    // rendered results would still be those of the previously selected namespace.
    scope() {
      this.executeQuery();
    },
  },
  mounted() {
    this.executeQuery();
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

        // Honor an explicit `limit:` from the user. Otherwise, only paginated
        // display types (lists, tables) get the default page size; aggregated
        // displays (charts) fetch the full result set in one round-trip.
        if (this.config.limit != null) {
          this.setVariable('limit', this.config.limit);
        } else if (this.isPaginatedDisplayWithDefaultLimit) {
          this.setVariable('limit', DEFAULT_PAGE_SIZE);
        }

        const executionResult = await execute(this.query, this.variables);

        this.data = await transform(executionResult, {
          fields: this.fields,
          mode: this.mode,
          source: this.source,
        });
        this.comparisonData = await this.fetchComparison();

        this.trackRender();
      } catch (error) {
        this.resetData();
        this.error = error;
      } finally {
        this.loading = false;
        this.emitChange();
      }
    },

    // Runs once and is never paginated: `loadMore` pages the main query alone, since two result
    // sets paged in step drift apart as soon as one page fails. A comparison that fails to
    // compile or run is dropped and reported, so the main result still renders without it.
    async fetchComparison() {
      if (!this.comparisonQuery) return undefined;

      try {
        const { query, variables, fields, mode, source } = await parse(
          this.comparisonQuery,
          this.scope,
        );
        const executionResult = await execute(query, variables);

        return await transform(executionResult, { fields, mode, source });
      } catch (error) {
        Sentry.captureException(error);
        return undefined;
      }
    },

    async loadMore() {
      try {
        this.setVariable('after', this.data.pageInfo?.endCursor);
        this.loading = true;
        this.emitChange();

        const executionResult = await execute(this.query, this.variables);

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
      this.error = error;
      this.emitChange();
    },
  },
};
</script>
<template>
  <div>
    <data-presenter
      v-if="hasDisplayType"
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
