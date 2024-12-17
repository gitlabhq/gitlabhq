<script>
import { GlTable } from '@gitlab/ui';
import { formatTimeSpent, localeDateFormat, newDate } from '~/lib/utils/datetime_utility';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import { s__ } from '~/locale';
import TimelogSourceCell from './timelog_source_cell.vue';

export default {
  components: {
    GlTable,
    UserAvatarLink,
    TimelogSourceCell,
  },
  props: {
    entries: {
      type: Array,
      required: true,
    },
    limitToHours: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      fields: [
        {
          key: 'spentAt',
          label: s__('TimeTrackingReport|Spent at'),
          tdClass: 'md:gl-w-30',
        },
        {
          key: 'source',
          label: s__('TimeTrackingReport|Source'),
        },
        {
          key: 'user',
          label: s__('TimeTrackingReport|User'),
          tdClass: 'md:gl-w-20',
        },
        {
          key: 'timeSpent',
          label: s__('TimeTrackingReport|Time spent'),
          tdClass: 'md:gl-w-15',
        },
        {
          key: 'summary',
          label: s__('TimeTrackingReport|Summary'),
        },
      ],
    };
  },
  methods: {
    formatDate(date) {
      return localeDateFormat.asDateTimeFull.format(newDate(date));
    },
    formatTimeSpent(seconds) {
      return formatTimeSpent(seconds, this.limitToHours);
    },
    extractTimelogSummary(timelog) {
      const { note, summary } = timelog;
      return note?.body || summary;
    },
  },
};
</script>

<template>
  <gl-table :items="entries" :fields="fields" stacked="md" show-empty>
    <template #cell(spentAt)="{ item: { spentAt } }">
      <div data-testid="date-container" class="!gl-text-left">{{ formatDate(spentAt) }}</div>
    </template>

    <template #cell(source)="{ item }">
      <timelog-source-cell :timelog="item" />
    </template>

    <template #cell(user)="{ item: { user } }">
      <user-avatar-link
        class="gl-flex gl-text-default hover:gl-text-default"
        :link-href="user.webPath"
        :img-src="user.avatarUrl"
        :img-size="16"
        :img-alt="user.name"
        :tooltip-text="user.name"
        :username="user.name"
      />
    </template>

    <template #cell(timeSpent)="{ item: { timeSpent } }">
      <div data-testid="time-spent-container" class="!gl-text-left">
        {{ formatTimeSpent(timeSpent) }}
      </div>
    </template>

    <template #cell(summary)="{ item }">
      <div data-testid="summary-container" class="!gl-text-left">
        {{ extractTimelogSummary(item) }}
      </div>
    </template>
  </gl-table>
</template>
