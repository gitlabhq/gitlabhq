<script>
import { pick } from 'lodash-es';
import { sha256 } from '~/lib/utils/text_utility';
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
  },
  emits: ['change'],
  data() {
    return {
      loading: false,

      data: undefined,
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
  },
  mounted() {
    this.executeQuery();
  },
  methods: {
    resetData() {
      this.data = undefined;
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
        const { query, config, variables, fields, mode, source } = await parse(this.glqlQuery);

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

        this.trackRender();
      } catch (error) {
        this.resetData();
        this.error = error;
      } finally {
        this.loading = false;
        this.emitChange();
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
      :fields="fields"
      :display-type="config.display"
      :display-config="config.displayConfig"
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
