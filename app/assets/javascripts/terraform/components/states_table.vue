<script>
import { GlBadge, GlIcon, GlSprintf, GlTable, GlTooltip } from '@gitlab/ui';
import { s__ } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  components: {
    GlBadge,
    GlIcon,
    GlSprintf,
    GlTable,
    GlTooltip,
    TimeAgoTooltip,
  },
  mixins: [timeagoMixin],
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
  methods: {
    createdByUserName(item) {
      return item.latestVersion?.createdByUser?.name;
    },
    lockedByUserName(item) {
      return item.lockedByUser?.name || s__('Terraform|Unknown User');
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

        <div v-if="item.lockedAt" id="terraformLockedBadgeContainer" class="gl-mx-2">
          <gl-badge id="terraformLockedBadge">
            <gl-icon name="lock" />
            {{ s__('Terraform|Locked') }}
          </gl-badge>

          <gl-tooltip
            container="terraformLockedBadgeContainer"
            placement="right"
            target="terraformLockedBadge"
          >
            <gl-sprintf :message="s__('Terraform|Locked by %{user} %{timeAgo}')">
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
        <gl-sprintf :message="s__('Terraform|%{user} updated %{timeAgo}')">
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
  </gl-table>
</template>
