<script>
import { GlBadge, GlIcon, GlSprintf, GlTable, GlTooltip } from '@gitlab/ui';
import { s__ } from '~/locale';
import StateActions from './states_table_actions.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  components: {
    GlBadge,
    GlIcon,
    GlSprintf,
    GlTable,
    GlTooltip,
    StateActions,
    TimeAgoTooltip,
  },
  mixins: [timeagoMixin],
  props: {
    states: {
      required: true,
      type: Array,
    },
    terraformAdmin: {
      required: false,
      type: Boolean,
      default: false,
    },
  },
  computed: {
    fields() {
      const columns = [
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

      if (this.terraformAdmin) {
        columns.push({
          key: 'actions',
          thClass: 'gl-display-none',
          tdClass: 'gl-w-10',
        });
      }

      return columns;
    },
  },
  i18n: {
    locked: s__('Terraform|Locked'),
    lockedByUser: s__('Terraform|Locked by %{user} %{timeAgo}'),
    unknownUser: s__('Terraform|Unknown User'),
    updatedUser: s__('Terraform|%{user} updated %{timeAgo}'),
  },
  methods: {
    createdByUserName(item) {
      return item.latestVersion?.createdByUser?.name;
    },
    lockedByUserName(item) {
      return item.lockedByUser?.name || this.$options.i18n.unknownUser;
    },
    updatedTime(item) {
      return item.latestVersion?.updatedAt || item.updatedAt;
    },
  },
};
</script>

<template>
  <gl-table :items="states" :fields="fields" data-testid="terraform-states-table">
    <template #cell(name)="{ item }">
      <div class="gl-display-flex align-items-center" data-testid="terraform-states-table-name">
        <p class="gl-font-weight-bold gl-m-0 gl-text-gray-900">
          {{ item.name }}
        </p>

        <div v-if="item.lockedAt" :id="`terraformLockedBadgeContainer${item.name}`" class="gl-mx-2">
          <gl-badge :id="`terraformLockedBadge${item.name}`">
            <gl-icon name="lock" />
            {{ $options.i18n.locked }}
          </gl-badge>

          <gl-tooltip
            :container="`terraformLockedBadgeContainer${item.name}`"
            :target="`terraformLockedBadge${item.name}`"
            placement="right"
          >
            <gl-sprintf :message="$options.i18n.lockedByUser">
              <template #user>
                {{ lockedByUserName(item) }}
              </template>

              <template #timeAgo>
                {{ timeFormatted(item.lockedAt) }}
              </template>
            </gl-sprintf>
          </gl-tooltip>
        </div>
      </div>
    </template>

    <template #cell(updated)="{ item }">
      <p class="gl-m-0" data-testid="terraform-states-table-updated">
        <gl-sprintf :message="$options.i18n.updatedUser">
          <template #user>
            <span v-if="item.latestVersion">
              {{ createdByUserName(item) }}
            </span>
          </template>

          <template #timeAgo>
            <time-ago-tooltip :time="updatedTime(item)" />
          </template>
        </gl-sprintf>
      </p>
    </template>

    <template v-if="terraformAdmin" #cell(actions)="{ item }">
      <state-actions :state="item" />
    </template>
  </gl-table>
</template>
