<script>
import { GlIntersperse, GlTableLite } from '@gitlab/ui';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import { s__ } from '~/locale';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { tableField } from '../utils';
import { I18N_STATUS_NEVER_CONTACTED } from '../constants';
import RunnerStatusBadge from './runner_status_badge.vue';
import RunnerJobStatusBadge from './runner_job_status_badge.vue';

export default {
  name: 'RunnerManagersTable',
  components: {
    GlTableLite,
    TimeAgo,
    HelpPopover,
    GlIntersperse,
    RunnerStatusBadge,
    RunnerJobStatusBadge,
    RunnerUpgradeStatusIcon: () =>
      import('ee_component/ci/runner/components/runner_upgrade_status_icon.vue'),
  },
  props: {
    items: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  fields: [
    tableField({ key: 'systemId', label: s__('Runners|System ID') }),
    tableField({ key: 'status', label: s__('Runners|Status') }),
    tableField({ key: 'version', label: s__('Runners|Version') }),
    tableField({ key: 'ipAddress', label: s__('Runners|IP Address') }),
    tableField({ key: 'executorName', label: s__('Runners|Executor') }),
    tableField({ key: 'architecturePlatform', label: s__('Runners|Arch/Platform') }),
    tableField({
      key: 'contactedAt',
      label: s__('Runners|Last contact'),
      tdClass: ['gl-text-right'],
      thClasses: ['gl-text-right'],
    }),
  ],
  I18N_STATUS_NEVER_CONTACTED,
};
</script>

<template>
  <gl-table-lite :fields="$options.fields" :items="items">
    <template #head(systemId)="{ label }">
      {{ label }}
      <help-popover>
        {{ s__('Runners|The ID of the machine hosting the runner.') }}
      </help-popover>
    </template>
    <template #cell(status)="{ item = {} }">
      <runner-status-badge
        class="gl-align-middle"
        :contacted-at="item.contactedAt"
        :status="item.status"
      />
      <runner-job-status-badge class="gl-align-middle" :job-status="item.jobExecutionStatus" />
    </template>
    <template #cell(version)="{ item = {} }">
      {{ item.version }}
      <template v-if="item.revision">({{ item.revision }})</template>
      <runner-upgrade-status-icon :upgrade-status="item.upgradeStatus" />
    </template>
    <template #cell(architecturePlatform)="{ item = {} }">
      <gl-intersperse separator="/">
        <span v-if="item.architectureName">{{ item.architectureName }}</span>
        <span v-if="item.platformName">{{ item.platformName }}</span>
      </gl-intersperse>
    </template>
    <template #cell(contactedAt)="{ item = {} }">
      <template v-if="item.contactedAt">
        <time-ago :time="item.contactedAt" />
      </template>
      <template v-else>{{ $options.I18N_STATUS_NEVER_CONTACTED }}</template>
    </template>
  </gl-table-lite>
</template>
