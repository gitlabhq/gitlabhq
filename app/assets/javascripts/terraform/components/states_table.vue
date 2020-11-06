<script>
import { GlBadge, GlIcon, GlSprintf, GlTable } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    GlBadge,
    GlIcon,
    GlSprintf,
    GlTable,
    TimeAgoTooltip,
  },
  props: {
    states: {
      required: true,
      type: Array,
    },
  },
  computed: {
    fields() {
      return [
        {
          key: 'name',
          thClass: 'gl-display-none',
        },
        {
          key: 'updated',
          thClass: 'gl-display-none',
          tdClass: 'gl-text-right',
        },
      ];
    },
  },
};
</script>

<template>
  <gl-table :items="states" :fields="fields" data-testid="terraform-states-table">
    <template #cell(name)="{ item }">
      <p
        class="gl-font-weight-bold gl-m-0 gl-text-gray-900"
        data-testid="terraform-states-table-name"
      >
        {{ item.name }}

        <gl-badge v-if="item.lockedAt">
          <gl-icon name="lock" />
          {{ s__('Terraform|Locked') }}
        </gl-badge>
      </p>
    </template>

    <template #cell(updated)="{ item }">
      <p class="gl-m-0" data-testid="terraform-states-table-updated">
        <gl-sprintf :message="s__('Terraform|updated %{timeStart}time%{timeEnd}')">
          <template #time>
            <time-ago-tooltip :time="item.updatedAt" />
          </template>
        </gl-sprintf>
      </p>
    </template>
  </gl-table>
</template>
