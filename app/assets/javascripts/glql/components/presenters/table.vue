<script>
import { GlBadge, GlIcon, GlSkeletonLoader, GlTooltipDirective } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { FIELD_TYPES } from '../../constants';
import { sortBy } from '../../core/sorter';
import {
  baseFieldKeyOf,
  dimensionsOf,
  labelWithParameter,
  metricsOf,
} from '../../utils/chart_data';
import ThResizable from '../common/th_resizable.vue';
import FieldPresenter from './field.vue';
import { trendPresentationFor } from './utils/stat';
import { formatChange } from './utils/trend';
import {
  TREND_CHANGE_KEY,
  TREND_PREVIOUS_KEY,
  hasTemporalDimension,
  hasUniqueRowKeys,
  withTrendValues,
} from './utils/table';

const DEFAULT_PAGE_SIZE = 5;

// Rendered when a row has no counterpart in the previous period, so its change is unknown.
// Kept distinct from a neutral `0%` badge, which means the row was found and did not move.
const NO_TREND = '—';

// Holds a row's badge config, kept apart from TREND_CHANGE_KEY because only that one is
// sortable.
const TREND_CELL_KEY = '__trendCell';

export default {
  name: 'TablePresenter',
  components: {
    GlBadge,
    GlIcon,
    GlSkeletonLoader,
    ThResizable,
    FieldPresenter,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    data: {
      required: false,
      type: Object,
      default: () => ({ nodes: [] }),
    },
    comparisonData: {
      required: false,
      type: Object,
      default: null,
    },
    fields: {
      required: false,
      type: Array,
      default: () => [],
    },
    loading: {
      required: false,
      type: [Boolean, Number],
      default: false,
    },
    /**
     * Key of the metric the trend column compares, matched against a field's alias or its
     * base key. Optional when the table selects a single metric.
     */
    trendMetric: {
      required: false,
      type: String,
      default: '',
    },
    source: {
      required: false,
      type: String,
      default: '',
    },
  },
  emits: { error: null },
  data() {
    return {
      items: [],
      sortOptions: { fieldName: null, ascending: true },
    };
  },
  computed: {
    pageSize() {
      return typeof this.loading === 'number' ? this.loading : DEFAULT_PAGE_SIZE;
    },
    dimensions() {
      return dimensionsOf(this.fields);
    },
    metrics() {
      return metricsOf(this.fields);
    },
    trendField() {
      if (!this.trendMetric) return this.metrics.length === 1 ? this.metrics[0] : null;

      return (
        this.metrics.find(
          (metric) =>
            metric.key === this.trendMetric || baseFieldKeyOf(metric) === this.trendMetric,
        ) ?? null
      );
    },
    validationError() {
      // Only a panel that asked for a trend can misconfigure one.
      if (!this.comparisonData) return null;

      if (this.trendMetric && !this.trendField) {
        return sprintf(__('Unknown metric for `trendMetric`: `%{metric}`.'), {
          metric: this.trendMetric,
        });
      }
      if (!this.trendMetric && this.metrics.length > 1) {
        return __('table display type requires `trendMetric` when several metrics are selected');
      }

      return null;
    },
    trendColumn() {
      if (!this.trendField || !this.comparisonData?.nodes?.length) return null;
      if (hasTemporalDimension(this.dimensions)) return null;
      // Both periods: a duplicate identity on either side mispairs rows on the other.
      if (!hasUniqueRowKeys(this.data.nodes, this.dimensions)) return null;
      if (!hasUniqueRowKeys(this.comparisonData.nodes, this.dimensions)) return null;

      return {
        key: TREND_CHANGE_KEY,
        label: s__('Glql|vs previous period'),
        type: FIELD_TYPES.METRIC,
      };
    },
    rows() {
      if (!this.trendColumn) return this.data.nodes;

      return withTrendValues(this.data.nodes, {
        comparisonNodes: this.comparisonData.nodes,
        dimensions: this.dimensions,
        metric: this.trendField,
      }).map((row) => ({ ...row, [TREND_CELL_KEY]: this.trendCellFor(row) }));
    },
    columns() {
      return this.trendColumn ? [...this.fields, this.trendColumn] : this.fields;
    },
  },
  watch: {
    rows: {
      immediate: true,
      handler(rows) {
        this.items = rows.slice();
      },
    },
    validationError: {
      immediate: true,
      handler(message) {
        if (message) this.$emit('error', new Error(message));
      },
    },
  },
  methods: {
    baseFieldKeyOf,
    labelWithParameter,
    isTrendColumn(field) {
      return field.key === TREND_CHANGE_KEY;
    },
    trendCellFor(row) {
      const trend = trendPresentationFor(this.source, this.trendField, {
        value: row[this.trendField.key],
        previousValue: row[TREND_PREVIOUS_KEY],
      });
      if (!trend) return null;

      const change = row[TREND_CHANGE_KEY];

      return {
        ...trend,
        // The column header already names the comparison, so the cell drops the "vs prior"
        // suffix the stat badge carries. A move away from 0 has no percentage to show.
        text: change == null ? trend.metaText : formatChange(change),
      };
    },
    trendCellIn(item) {
      return item[TREND_CELL_KEY] ?? null;
    },
    sortBy(fieldName) {
      const { options, items } = sortBy(this.items, fieldName, this.sortOptions);
      this.items = items;
      this.sortOptions = options;
    },
  },
  NO_TREND,
};
</script>
<template>
  <div class="gl-table-shadow" data-print-scale-container>
    <table class="!gl-my-0 gl-min-w-full gl-overflow-y-hidden" data-print-scale-target>
      <thead class="!gl-border-b gl-text-sm">
        <tr>
          <th-resizable
            v-for="(field, fieldIndex) in columns"
            :key="field.key"
            class="gl-relative !gl-bg-default !gl-p-0 !gl-text-subtle dark:!gl-bg-strong"
          >
            <div
              :data-testid="`column-${fieldIndex}`"
              class="gl-l-0 gl-r-0 gl-absolute gl-w-full gl-cursor-pointer gl-truncate gl-bg-default gl-px-5 gl-py-3 hover:gl-bg-subtle"
              @click="sortBy(field.key)"
            >
              {{ labelWithParameter(field) }}
              <gl-icon
                v-if="sortOptions.fieldName === field.key"
                :name="sortOptions.ascending ? 'arrow-up' : 'arrow-down'"
              />
            </div>
            <div class="gl-pointer-events-none gl-py-3">&nbsp;</div>
          </th-resizable>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="(item, itemIndex) in items"
          :key="item.id"
          :data-testid="`table-row-${itemIndex}`"
        >
          <td
            v-for="field in columns"
            :key="field.key"
            class="!gl-border-l-0 !gl-border-r-0 gl-bg-default !gl-px-5 !gl-py-3"
          >
            <template v-if="isTrendColumn(field)">
              <gl-badge
                v-if="trendCellIn(item)"
                v-gl-tooltip
                :title="trendCellIn(item).metaTooltip"
                :variant="trendCellIn(item).variant"
                :icon="trendCellIn(item).metaIcon"
                data-testid="trend-badge"
              >
                {{ trendCellIn(item).text }}
              </gl-badge>
              <span v-else class="gl-text-subtle" data-testid="trend-unknown">
                {{ $options.NO_TREND }}
              </span>
            </template>
            <field-presenter
              v-else
              :item="item"
              :field-key="field.key"
              :presenter-key="baseFieldKeyOf(field)"
            />
          </td>
        </tr>
        <template v-if="loading">
          <tr v-for="i in pageSize" :key="i">
            <td
              v-for="field in columns"
              :key="field.key"
              class="!gl-border-l-0 !gl-border-r-0 !gl-border-t-0 gl-bg-default !gl-px-5 !gl-py-3"
            >
              <gl-skeleton-loader :width="60" :lines="1" :equal-width-lines="true" />
            </td>
          </tr>
        </template>
      </tbody>
    </table>
  </div>
</template>
