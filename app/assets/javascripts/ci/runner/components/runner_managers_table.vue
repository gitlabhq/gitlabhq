<script>
import { GlIntersperse, GlTableLite } from '@gitlab/ui';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import { s__ } from '~/locale';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { tableField } from '../utils';

export default {
  name: 'RunnerManagersTable',
  components: {
    GlTableLite,
    TimeAgo,
    HelpPopover,
    GlIntersperse,
  },
  props: {
    items: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      skip: true,
      expanded: false,
      managers: [],
    };
  },
  fields: [
    tableField({ key: 'systemId', label: s__('Runners|System ID') }),
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
};
</script>

<template>
  <gl-table-lite :fields="$options.fields" :items="items">
    <template #head(systemId)="{ label }">
      {{ label }}
      <help-popover>
        {{ s__('Runners|The unique ID for each runner that uses this configuration.') }}
      </help-popover>
    </template>
    <template #cell(version)="{ item = {} }">
      {{ item.version }}
      <template v-if="item.revision">({{ item.revision }})</template>
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
      <template v-else>{{ s__('Runners|Never contacted') }}</template>
    </template>
  </gl-table-lite>
</template>
