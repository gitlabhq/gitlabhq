<script>
import { GlLoadingIcon, GlTable } from '@gitlab/ui';
import createFlash from '~/flash';
import { TYPE_ISSUE, TYPE_MERGE_REQUEST } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { formatDate, parseSeconds, stringifyTime } from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';
import { timelogQueries } from '~/sidebar/constants';

const TIME_DATE_FORMAT = 'mmmm d, yyyy, HH:MM ("UTC:" o)';

export default {
  components: {
    GlLoadingIcon,
    GlTable,
  },
  inject: ['issuableType'],
  props: {
    limitToHours: {
      type: Boolean,
      default: false,
      required: false,
    },
    issuableId: {
      type: String,
      required: true,
    },
  },
  data() {
    return { report: [], isLoading: true };
  },
  apollo: {
    report: {
      query() {
        return timelogQueries[this.issuableType].query;
      },
      variables() {
        return {
          id: convertToGraphQLId(this.getGraphQLEntityType(), this.issuableId),
        };
      },
      update(data) {
        this.isLoading = false;
        return this.extractTimelogs(data);
      },
      error() {
        createFlash({ message: __('Something went wrong. Please try again.') });
      },
    },
  },
  methods: {
    isIssue() {
      return this.issuableType === 'issue';
    },
    getGraphQLEntityType() {
      return this.isIssue() ? TYPE_ISSUE : TYPE_MERGE_REQUEST;
    },
    extractTimelogs(data) {
      const timelogs = data?.issuable?.timelogs?.nodes || [];
      return timelogs.slice().sort((a, b) => new Date(a.spentAt) - new Date(b.spentAt));
    },
    formatDate(date) {
      return formatDate(date, TIME_DATE_FORMAT);
    },
    getNote(note) {
      return note?.body;
    },
    getTotalTimeSpent() {
      const seconds = this.report.reduce((acc, item) => acc + item.timeSpent, 0);
      return this.formatTimeSpent(seconds);
    },
    formatTimeSpent(seconds) {
      const negative = seconds < 0;
      return (
        (negative ? '- ' : '') +
        stringifyTime(parseSeconds(seconds, { limitToHours: this.limitToHours }))
      );
    },
  },
  fields: [
    { key: 'spentAt', label: __('Spent At'), sortable: true },
    { key: 'user', label: __('User'), sortable: true },
    { key: 'timeSpent', label: __('Time Spent'), sortable: true },
    { key: 'note', label: __('Note'), sortable: true },
  ],
};
</script>

<template>
  <div>
    <div v-if="isLoading"><gl-loading-icon size="md" /></div>
    <gl-table v-else :items="report" :fields="$options.fields" foot-clone>
      <template #cell(spentAt)="{ item: { spentAt } }">
        <div>{{ formatDate(spentAt) }}</div>
      </template>
      <template #foot(spentAt)>&nbsp;</template>

      <template #cell(user)="{ item: { user } }">
        <div>{{ user.name }}</div>
      </template>
      <template #foot(user)>&nbsp;</template>

      <template #cell(timeSpent)="{ item: { timeSpent } }">
        <div>{{ formatTimeSpent(timeSpent) }}</div>
      </template>
      <template #foot(timeSpent)>
        <div>{{ getTotalTimeSpent() }}</div>
      </template>

      <template #cell(note)="{ item: { note } }">
        <div>{{ getNote(note) }}</div>
      </template>
      <template #foot(note)>&nbsp;</template>
    </gl-table>
  </div>
</template>
