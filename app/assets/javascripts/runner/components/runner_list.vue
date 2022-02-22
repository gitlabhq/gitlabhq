<script>
import { GlTableLite, GlTooltipDirective, GlSkeletonLoader } from '@gitlab/ui';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __, s__ } from '~/locale';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { formatJobCount, tableField } from '../utils';
import RunnerActionsCell from './cells/runner_actions_cell.vue';
import RunnerSummaryCell from './cells/runner_summary_cell.vue';
import RunnerStatusCell from './cells/runner_status_cell.vue';
import RunnerTags from './runner_tags.vue';

export default {
  components: {
    GlTableLite,
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
  computed: {
    tableClass() {
      // <gl-table-lite> does not provide a busy state, add
      // simple support for it.
      // See http://bootstrap-vue.org/docs/components/table#table-busy-state
      return {
        'gl-opacity-6': this.loading,
      };
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
    <gl-table-lite
      :aria-busy="loading"
      :class="tableClass"
      :items="runners"
      :fields="$options.fields"
      :tbody-tr-attr="runnerTrAttr"
      data-testid="runner-list"
      stacked="md"
      primary-key="id"
      fixed
    >
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
    </gl-table-lite>

    <template v-if="!runners.length && loading">
      <gl-skeleton-loader v-for="i in 4" :key="i" />
    </template>
  </div>
</template>
