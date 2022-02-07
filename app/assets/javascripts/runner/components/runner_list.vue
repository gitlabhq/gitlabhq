<script>
import { GlTable, GlTooltipDirective, GlSkeletonLoader } from '@gitlab/ui';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { formatNumber, __, s__ } from '~/locale';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { RUNNER_JOB_COUNT_LIMIT } from '../constants';
import RunnerActionsCell from './cells/runner_actions_cell.vue';
import RunnerSummaryCell from './cells/runner_summary_cell.vue';
import RunnerStatusCell from './cells/runner_status_cell.vue';
import RunnerTags from './runner_tags.vue';

const tableField = ({ key, label = '', thClasses = [] }) => {
  return {
    key,
    label,
    thClass: [
      'gl-bg-transparent!',
      'gl-border-b-solid!',
      'gl-border-b-gray-100!',
      'gl-border-b-1!',
      ...thClasses,
    ],
    tdAttr: {
      'data-testid': `td-${key}`,
    },
  };
};

export default {
  components: {
    GlTable,
    GlSkeletonLoader,
    TooltipOnTruncate,
    TimeAgo,
    RunnerActionsCell,
    RunnerSummaryCell,
    RunnerTags,
    RunnerStatusCell,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
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
  methods: {
    formatJobCount(jobCount) {
      if (jobCount > RUNNER_JOB_COUNT_LIMIT) {
        return `${formatNumber(RUNNER_JOB_COUNT_LIMIT)}+`;
      }
      return formatNumber(jobCount);
    },
    runnerTrAttr(runner) {
      if (runner) {
        return {
          'data-testid': `runner-row-${getIdFromGraphQLId(runner.id)}`,
        };
      }
      return {};
    },
  },
  fields: [
    tableField({ key: 'status', label: s__('Runners|Status') }),
    tableField({ key: 'summary', label: s__('Runners|Runner'), thClasses: ['gl-lg-w-25p'] }),
    tableField({ key: 'version', label: __('Version') }),
    tableField({ key: 'ipAddress', label: __('IP') }),
    tableField({ key: 'jobCount', label: __('Jobs') }),
    tableField({ key: 'tagList', label: __('Tags'), thClasses: ['gl-lg-w-25p'] }),
    tableField({ key: 'contactedAt', label: __('Last contact') }),
    tableField({ key: 'actions', label: '' }),
  ],
};
</script>
<template>
  <div>
    <gl-table
      :busy="loading"
      :items="runners"
      :fields="$options.fields"
      :tbody-tr-attr="runnerTrAttr"
      data-testid="runner-list"
      stacked="md"
      primary-key="id"
      fixed
    >
      <template v-if="!runners.length" #table-busy>
        <gl-skeleton-loader v-for="i in 4" :key="i" />
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

      <template #cell(ipAddress)="{ item: { ipAddress } }">
        <tooltip-on-truncate class="gl-display-block gl-text-truncate" :title="ipAddress">
          {{ ipAddress }}
        </tooltip-on-truncate>
      </template>

      <template #cell(jobCount)="{ item: { jobCount } }">
        {{ formatJobCount(jobCount) }}
      </template>

      <template #cell(tagList)="{ item: { tagList } }">
        <runner-tags :tag-list="tagList" size="sm" />
      </template>

      <template #cell(contactedAt)="{ item: { contactedAt } }">
        <time-ago v-if="contactedAt" :time="contactedAt" />
        <template v-else>{{ __('Never') }}</template>
      </template>

      <template #cell(actions)="{ item }">
        <runner-actions-cell :runner="item" />
      </template>
    </gl-table>
  </div>
</template>
