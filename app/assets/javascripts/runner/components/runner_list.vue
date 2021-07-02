<script>
import { GlTable, GlTooltipDirective, GlSkeletonLoader } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { formatNumber, sprintf, __, s__ } from '~/locale';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { RUNNER_JOB_COUNT_LIMIT } from '../constants';
import RunnerActionsCell from './cells/runner_actions_cell.vue';
import RunnerNameCell from './cells/runner_name_cell.vue';
import RunnerTypeCell from './cells/runner_type_cell.vue';
import RunnerTags from './runner_tags.vue';

const tableField = ({ key, label = '', width = 10 }) => {
  return {
    key,
    label,
    thClass: [
      `gl-w-${width}p`,
      'gl-bg-transparent!',
      'gl-border-b-solid!',
      'gl-border-b-gray-100!',
      'gl-py-5!',
      'gl-px-0!',
      'gl-border-b-1!',
    ],
    tdClass: ['gl-py-5!', 'gl-px-1!'],
    tdAttr: {
      'data-testid': `td-${key}`,
    },
  };
};

export default {
  components: {
    GlTable,
    GlSkeletonLoader,
    TimeAgo,
    RunnerActionsCell,
    RunnerNameCell,
    RunnerTags,
    RunnerTypeCell,
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
    activeRunnersCount: {
      type: Number,
      required: true,
    },
  },
  computed: {
    activeRunnersMessage() {
      return sprintf(__('Runners currently online: %{active_runners_count}'), {
        active_runners_count: formatNumber(this.activeRunnersCount),
      });
    },
  },
  methods: {
    formatProjectCount(projectCount) {
      if (projectCount === null) {
        return __('n/a');
      }
      return formatNumber(projectCount);
    },
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
    tableField({ key: 'type', label: __('Type/State') }),
    tableField({ key: 'name', label: s__('Runners|Runner'), width: 30 }),
    tableField({ key: 'version', label: __('Version') }),
    tableField({ key: 'ipAddress', label: __('IP Address') }),
    tableField({ key: 'projectCount', label: __('Projects'), width: 5 }),
    tableField({ key: 'jobCount', label: __('Jobs'), width: 5 }),
    tableField({ key: 'tagList', label: __('Tags') }),
    tableField({ key: 'contactedAt', label: __('Last contact') }),
    tableField({ key: 'actions', label: '' }),
  ],
};
</script>
<template>
  <div>
    <div class="gl-text-right" data-testid="active-runners-message">{{ activeRunnersMessage }}</div>
    <gl-table
      :busy="loading"
      :items="runners"
      :fields="$options.fields"
      :tbody-tr-attr="runnerTrAttr"
      stacked="md"
      fixed
    >
      <template v-if="!runners.length" #table-busy>
        <gl-skeleton-loader v-for="i in 4" :key="i" />
      </template>

      <template #cell(type)="{ item }">
        <runner-type-cell :runner="item" />
      </template>

      <template #cell(name)="{ item }">
        <runner-name-cell :runner="item" />
      </template>

      <template #cell(version)="{ item: { version } }">
        {{ version }}
      </template>

      <template #cell(ipAddress)="{ item: { ipAddress } }">
        {{ ipAddress }}
      </template>

      <template #cell(projectCount)="{ item: { projectCount } }">
        {{ formatProjectCount(projectCount) }}
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
