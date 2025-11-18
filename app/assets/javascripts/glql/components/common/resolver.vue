<script>
import { pick } from 'lodash';
import { sha256 } from '~/lib/utils/text_utility';
import { InternalEvents } from '~/tracking';
import { parse } from '../../core/parser';
import { execute } from '../../core/executor';
import { transform } from '../../core/transformer';
import DataPresenter from '../presenters/data.vue';
import GlqlPagination from './pagination.vue';

const DEFAULT_PAGE_SIZE = 20;

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
  },
  data() {
    return {
      loading: false,

      data: undefined,
      query: undefined,
      config: undefined,
      variables: undefined,
      fields: undefined,
      aggregate: undefined,
      groupBy: undefined,
      error: undefined,
    };
  },
  computed: {
    hasDisplayType() {
      return Boolean(this.config?.display);
    },
    hasNextPage() {
      return Boolean(this.data?.count && this.data.nodes?.length < this.data.count);
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
      this.aggregate = undefined;
      this.groupBy = undefined;
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
          'aggregate',
          'groupBy',
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
        const { query, config, variables, fields, aggregate, groupBy } = await parse(
          this.glqlQuery,
        );

        this.query = query;
        this.config = config;
        this.variables = variables;
        this.fields = fields;
        this.aggregate = aggregate;
        this.groupBy = groupBy;

        this.setVariable('limit', this.config.limit ?? DEFAULT_PAGE_SIZE);
        this.data = await transform(await execute(this.query, this.variables), this.config);

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
        this.setVariable('limit', DEFAULT_PAGE_SIZE);
        this.loading = true;
        this.emitChange();

        const data = await transform(await execute(this.query, this.variables), this.config);
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
      try {
        this.trackEvent('render_glql_block', { label: await sha256(this.glqlQuery) });
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
      :aggregate="aggregate"
      :group-by="groupBy"
      :display-type="config.display"
      :loading="loading"
      @error="handlePresenterError"
    />
    <div v-if="hasNextPage" class="glql-load-more gl-border-t gl-border-section gl-p-3">
      <glql-pagination
        :count="data.nodes.length"
        :total-count="data.count"
        :loading="loading"
        @loadMore="loadMore"
      />
    </div>
  </div>
</template>
