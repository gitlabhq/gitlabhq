<script>
import { GlFormCheckbox, GlTableLite, GlTooltipDirective, GlSkeletonLoader } from '@gitlab/ui';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __, s__ } from '~/locale';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import checkedRunnerIdsQuery from '../graphql/list/checked_runner_ids.query.graphql';
import { formatJobCount, tableField } from '../utils';
import RunnerSummaryCell from './cells/runner_summary_cell.vue';
import RunnerStatusPopover from './runner_status_popover.vue';
import RunnerStatusCell from './cells/runner_status_cell.vue';

const defaultFields = [
  tableField({ key: 'status', label: s__('Runners|Status'), thClasses: ['gl-w-15p'] }),
  tableField({ key: 'summary', label: s__('Runners|Runner'), thClasses: ['gl-lg-w-40p'] }),
  tableField({ key: 'version', label: __('Version') }),
  tableField({ key: 'jobCount', label: __('Jobs') }),
  tableField({ key: 'contactedAt', label: __('Last contact') }),
  tableField({ key: 'actions', label: '' }),
];

export default {
  components: {
    GlFormCheckbox,
    GlTableLite,
    GlSkeletonLoader,
    TooltipOnTruncate,
    TimeAgo,
    RunnerStatusPopover,
    RunnerSummaryCell,
    RunnerStatusCell,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  apollo: {
    checkedRunnerIds: {
      query: checkedRunnerIdsQuery,
      skip() {
        return !this.checkable;
      },
    },
  },
  props: {
    checkable: {
      type: Boolean,
      required: false,
      default: false,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    runners: {
      type: Array,
      required: true,
    },
  },
  emits: ['checked'],
  data() {
    return { checkedRunnerIds: [] };
  },
  computed: {
    tableClass() {
      // <gl-table-lite> does not provide a busy state, add
      // simple support for it.
      // See http://bootstrap-vue.org/docs/components/table#table-busy-state
      return {
        'gl-opacity-6': this.loading,
      };
    },
    fields() {
      if (this.checkable) {
        const checkboxField = tableField({
          key: 'checkbox',
          label: s__('Runners|Checkbox'),
          thClasses: ['gl-w-9'],
          tdClass: ['gl-text-center'],
        });
        return [checkboxField, ...defaultFields];
      }
      return defaultFields;
    },
  },
  methods: {
    formatJobCount(jobCount) {
      return formatJobCount(jobCount);
    },
    runnerTrAttr(runner) {
      if (runner) {
        return {
          'data-testid': `runner-row-${getIdFromGraphQLId(runner.id)}`,
        };
      }
      return {};
    },
    onCheckboxChange(runner, isChecked) {
      this.$emit('checked', {
        runner,
        isChecked,
      });
    },
    isChecked(runner) {
      return this.checkedRunnerIds.includes(runner.id);
    },
  },
};
</script>
<template>
  <div>
    <gl-table-lite
      :aria-busy="loading"
      :class="tableClass"
      :items="runners"
      :fields="fields"
      :tbody-tr-attr="runnerTrAttr"
      data-testid="runner-list"
      stacked="md"
      primary-key="id"
      fixed
    >
      <template #head(checkbox)>
        <slot name="head-checkbox"></slot>
      </template>

      <template #cell(checkbox)="{ item }">
        <gl-form-checkbox :checked="isChecked(item)" @change="onCheckboxChange(item, $event)" />
      </template>

      <template #head(status)="{ label }">
        {{ label }}
        <runner-status-popover />
      </template>

      <template #cell(status)="{ item }">
        <runner-status-cell :runner="item" />
      </template>

      <template #cell(summary)="{ item, index }">
        <runner-summary-cell :runner="item">
          <template #runner-name="{ runner }">
            <slot name="runner-name" :runner="runner" :index="index"></slot>
          </template>
        </runner-summary-cell>
      </template>

      <template #cell(version)="{ item: { version } }">
        <tooltip-on-truncate class="gl-display-block gl-text-truncate" :title="version">
          {{ version }}
        </tooltip-on-truncate>
      </template>

      <template #cell(jobCount)="{ item: { jobCount } }">
        {{ formatJobCount(jobCount) }}
      </template>

      <template #cell(contactedAt)="{ item: { contactedAt } }">
        <time-ago v-if="contactedAt" :time="contactedAt" />
        <template v-else>{{ __('Never') }}</template>
      </template>

      <template #cell(actions)="{ item }">
        <slot name="runner-actions-cell" :runner="item"></slot>
      </template>
    </gl-table-lite>

    <template v-if="!runners.length && loading">
      <gl-skeleton-loader v-for="i in 4" :key="i" />
    </template>
  </div>
</template>
