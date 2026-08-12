<script>
import { defineAsyncComponent } from 'vue';
import {
  GlIcon,
  GlLink,
  GlTable,
  GlTableLite,
  GlKeysetPagination,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __ } from '~/locale';
import { isExternal } from '~/lib/utils/url_utility';
import { formatVisualizationValue } from '../utils';

const DEFAULT_PAGE_SIZE = 20;
const SUPPORTED_FIELD_KEY_PATTERN = /^[a-zA-Z0-9][\w-]*(\.[a-zA-Z0-9][\w-]*)*$/;

const hasSupportedFieldKey = ({ key }) =>
  typeof key === 'string' && SUPPORTED_FIELD_KEY_PATTERN.test(key);

export default {
  name: 'DataTable',
  components: {
    GlIcon,
    GlLink,
    GlTable,
    GlTableLite,
    GlKeysetPagination,
    AssigneeAvatars: defineAsyncComponent(() => import('./assignee_avatars.vue')),
    CalculateSum: defineAsyncComponent(() => import('./calculate_sum.vue')),
    DiffLineChanges: defineAsyncComponent(() => import('./diff_line_changes.vue')),
    CalculatePercent: defineAsyncComponent(() => import('./calculate_percent.vue')),
    FormatNumber: defineAsyncComponent(() => import('./format_number.vue')),
    FormatTime: defineAsyncComponent(() => import('./format_time.vue')),
    FormatTimeRange: defineAsyncComponent(() => import('./format_time_range.vue')),
    MergeRequestLink: defineAsyncComponent(() => import('./merge_request_link.vue')),
    MilestoneLink: defineAsyncComponent(() => import('./milestone_link.vue')),
    ChangePercentageIndicator: defineAsyncComponent(
      () => import('./change_percentage_indicator.vue'),
    ),
    MetricLabel: defineAsyncComponent(() => import('./metric_label.vue')),
    ProjectAvatar: defineAsyncComponent(() => import('./project_avatar.vue')),
    TrendLine: defineAsyncComponent(() => import('./trend_line.vue')),
    UserLink: defineAsyncComponent(() => import('./user_link.vue')),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    data: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    options: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    query: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  emits: ['update-query'],
  computed: {
    tableComponent() {
      const hasSorting = this.sanitizedOptions.fields?.some(({ sortable }) => Boolean(sortable));
      return hasSorting ? GlTable : GlTableLite;
    },
    nodes() {
      return this.data.nodes || [];
    },
    pageInfo() {
      return this.data.pageInfo || {};
    },
    derivedFields() {
      // NOTE: we derive the field names from the keys in the first row of data
      // unless a custom field config is passed in the visualization options
      if (this.nodes.length < 1) {
        return null;
      }

      return Object.keys(this.nodes[0]).map((key) => ({
        key,
        tdClass: 'gl-truncate gl-max-w-0',
      }));
    },
    sanitizedOptions() {
      const { responsive, fixed, stacked, fields, refetchOnSort } = this.options;
      return {
        responsive: responsive ?? true,
        fixed: fixed ?? false,
        stacked: stacked ?? false,
        refetchOnSort: refetchOnSort ?? false,
        fields: fields ? fields.filter(hasSupportedFieldKey) : this.derivedFields,
      };
    },
    showPaginationControls() {
      return Boolean(this.pageInfo.hasPreviousPage || this.pageInfo.hasNextPage);
    },
  },
  methods: {
    isLink(value) {
      return Boolean(value?.text && value?.href);
    },
    isExternalLink(href) {
      return isExternal(href);
    },
    formatVisualizationValue,
    nextPage() {
      const { first, last, endCursor } = this.pageInfo;
      this.$emit('update-query', {
        pagination: {
          first: first ?? last ?? DEFAULT_PAGE_SIZE,
          endCursor,
        },
      });
    },
    prevPage() {
      const { first, last, startCursor } = this.pageInfo;
      this.$emit('update-query', {
        pagination: {
          last: last ?? first ?? DEFAULT_PAGE_SIZE,
          startCursor,
        },
      });
    },
    onSortingChanged({ sortBy, sortDesc }) {
      if (this.sanitizedOptions.refetchOnSort) {
        this.$emit('update-query', { sortBy, sortDesc, pagination: undefined });
      }
    },
  },
  i18n: {
    externalLink: __('external link'),
  },
};
</script>

<template>
  <div>
    <component
      :is="tableComponent"
      :fields="sanitizedOptions.fields"
      :responsive="sanitizedOptions.responsive"
      :fixed="sanitizedOptions.fixed"
      :stacked="sanitizedOptions.stacked"
      :no-local-sorting="sanitizedOptions.refetchOnSort"
      :items="nodes"
      :sort-by="query.sortBy"
      :sort-desc="query.sortDesc"
      hover
      borderless
      @sort-changed="onSortingChanged"
    >
      <template #head()="{ label, field: { tooltip } }">
        {{ label }}
        <gl-icon
          v-if="tooltip"
          v-gl-tooltip.hover
          class="gl-text-blue-600"
          name="information-o"
          :title="tooltip"
        />
      </template>
      <template #cell()="{ value, field }">
        <component :is="field.component" v-if="field.component" v-bind="value" />
        <gl-link v-else-if="isLink(value)" :href="value.href"
          >{{ formatVisualizationValue(value.text) }}
          <gl-icon
            v-if="isExternalLink(value.href)"
            name="external-link"
            :size="12"
            :aria-label="$options.i18n.externalLink"
            class="gl-ml-1"
          />
        </gl-link>
        <template v-else>
          {{ formatVisualizationValue(value) }}
        </template>
      </template>
    </component>
    <gl-keyset-pagination
      v-if="showPaginationControls"
      class="gl-m-3 gl-flex gl-items-center gl-justify-center"
      :has-previous-page="pageInfo.hasPreviousPage"
      :has-next-page="pageInfo.hasNextPage"
      :start-cursor="pageInfo.startCursor"
      :end-cursor="pageInfo.endCursor"
      @prev="prevPage"
      @next="nextPage"
    />
  </div>
</template>
