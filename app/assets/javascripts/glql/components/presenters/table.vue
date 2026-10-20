<script>
import { GlIcon, GlSkeletonLoader } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { FIELD_TYPES } from '../../constants';
import { sortBy } from '../../core/sorter';
import { baseFieldKeyOf, labelWithParameter } from '../../utils/chart_data';
import ThResizable from '../common/th_resizable.vue';
import FieldPresenter from './field.vue';
import { listDescriptionError, listDescriptionFor } from './utils/description';
import { hiddenMetricsError, visibleFieldsOf } from './utils/hidden_metrics';
import { NO_VALUE } from './utils/stat';

const DEFAULT_PAGE_SIZE = 5;

// Sources where a run can happen outside any project, so a null project is a real bucket.
// Everywhere else (Pipelines, for one) a null project means it was deleted or is unreadable.
const PROJECTLESS_SOURCES = ['DuoWorkflows', 'AgentPlatformSessions'];

// The engines return NULL for a hierarchy dimension when the flow sits outside the requested
// level, so the row is a real bucket that needs a name. A deleted namespace's ID no longer
// resolves either, which the panel description covers. The engines default `depth` to 1.
const DIMENSION_NULL_LABELS = {
  group: (field) => {
    // Parameters arrive from the compiler as strings.
    const depth = Number(field.parameters?.depth ?? 1);

    // At depth 2 the NULL bucket holds the top-level group's own projects and flows, plus
    // anything whose group the viewer cannot see.
    if (depth === 2) {
      return {
        text: s__('Glql|Not in a subgroup'),
        hint: s__('Glql|May include subgroups you cannot see'),
      };
    }

    return {
      text: s__('Glql|No group'),
      hint: sprintf(s__('Glql|No group at depth %{depth}'), { depth }),
    };
  },
  project: (field, source) => ({
    text: s__('Glql|No project'),
    hint: PROJECTLESS_SOURCES.includes(source)
      ? s__('Glql|Not tied to a project, or a project you cannot see')
      : null,
  }),
};

export default {
  name: 'TablePresenter',
  components: {
    GlIcon,
    GlSkeletonLoader,
    ThResizable,
    FieldPresenter,
  },
  inject: {
    getVisualizationTitle: { default: () => () => '' },
  },
  props: {
    data: {
      required: false,
      type: Object,
      default: () => ({ nodes: [] }),
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
    displayConfig: {
      required: false,
      type: Object,
      default: () => ({}),
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
    visualizationTitle() {
      return this.getVisualizationTitle();
    },
    pageSize() {
      return typeof this.loading === 'number' ? this.loading : DEFAULT_PAGE_SIZE;
    },
    description() {
      return listDescriptionFor({
        description: this.displayConfig?.description,
        fields: this.fields,
        data: this.data,
        loading: this.loading,
      });
    },
    validationError() {
      const descriptionError = listDescriptionError(this.displayConfig?.description, this.fields);
      if (descriptionError) return descriptionError;

      return hiddenMetricsError(this.displayConfig?.hiddenMetrics, this.fields);
    },
    rows() {
      return this.data.nodes;
    },
    columns() {
      return visibleFieldsOf(this.fields, this.displayConfig?.hiddenMetrics);
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
    isMetricColumn(field) {
      return field.type === FIELD_TYPES.METRIC;
    },
    dimensionNullLabel(field, item) {
      const label = DIMENSION_NULL_LABELS[baseFieldKeyOf(field)];
      if (label && field.type === FIELD_TYPES.DIMENSION && item[field.key] == null) {
        return label(field, this.source);
      }

      return null;
    },
    // A derived column renders one key but sorts by another.
    sortKeyOf(field) {
      return field.sortKey ?? field.key;
    },
    sortBy(field) {
      if (field.sortable === false) return;

      const { options, items } = sortBy(this.items, this.sortKeyOf(field), this.sortOptions);
      this.items = items;
      this.sortOptions = options;
    },
  },
  NO_VALUE,
};
</script>
<template>
  <div>
    <p v-if="description" class="gl-mb-3 gl-px-5 gl-pt-3 gl-text-subtle" data-testid="description">
      {{ description }}
    </p>
    <div class="gl-table-shadow" data-print-scale-container>
      <table class="!gl-my-0 gl-min-w-full gl-overflow-y-hidden" data-print-scale-target>
        <caption v-if="visualizationTitle" class="gl-sr-only" data-testid="table-caption">
          {{
            visualizationTitle
          }}
        </caption>
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
                @click="sortBy(field)"
              >
                {{ labelWithParameter(field) }}
                <gl-icon
                  v-if="sortOptions.fieldName === sortKeyOf(field)"
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
              <!-- A metric the user may not read comes back null, not as an error; "None" would read as zero. -->
              <span
                v-if="isMetricColumn(field) && item[field.key] == null"
                class="gl-text-subtle"
                data-testid="metric-no-value"
              >
                {{ $options.NO_VALUE }}
              </span>
              <!-- A null group or project dimension is a real bucket, not a missing value. -->
              <div
                v-else-if="dimensionNullLabel(field, item)"
                class="gl-text-subtle"
                data-testid="dimension-no-value"
              >
                {{ dimensionNullLabel(field, item).text }}
                <div
                  v-if="dimensionNullLabel(field, item).hint"
                  class="gl-text-sm"
                  data-testid="dimension-no-value-hint"
                >
                  {{ dimensionNullLabel(field, item).hint }}
                </div>
              </div>
              <field-presenter
                v-else
                :item="item"
                :field-key="field.key"
                :presenter-key="baseFieldKeyOf(field)"
                :parameters="field.parameters"
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
  </div>
</template>
