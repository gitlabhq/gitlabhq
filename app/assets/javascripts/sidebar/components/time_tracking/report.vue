<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlLoadingIcon, GlTableLite, GlButton, GlTooltipDirective } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { TYPENAME_ISSUE, TYPENAME_MERGE_REQUEST } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_ISSUE } from '~/issues/constants';
import { formatDate, parseSeconds, stringifyTime } from '~/lib/utils/datetime_utility';
import { __, s__ } from '~/locale';
import { timelogQueries } from '../../queries/constants';
import deleteTimelogMutation from '../../queries/delete_timelog.mutation.graphql';

const TIME_DATE_FORMAT = 'mmmm d, yyyy, HH:MM ("UTC:" o)';

export default {
  components: {
    GlLoadingIcon,
    GlTableLite,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
    return { report: [], isLoading: true, removingIds: [] };
  },
  apollo: {
    report: {
      query() {
        return timelogQueries[this.issuableType].query;
      },
      variables() {
        return this.getQueryVariables();
      },
      update(data) {
        this.isLoading = false;
        return this.extractTimelogs(data);
      },
      error() {
        createAlert({ message: __('Something went wrong. Please try again.') });
      },
    },
  },
  computed: {
    deleteButtonTooltip() {
      return s__('TimeTracking|Delete time spent');
    },
  },
  methods: {
    isDeletingTimelog(timelogId) {
      return this.removingIds.includes(timelogId);
    },
    isIssue() {
      return this.issuableType === TYPE_ISSUE;
    },
    getQueryVariables() {
      return {
        id: convertToGraphQLId(this.getGraphQLEntityType(), this.issuableId),
      };
    },
    getGraphQLEntityType() {
      return this.isIssue() ? TYPENAME_ISSUE : TYPENAME_MERGE_REQUEST;
    },
    extractTimelogs(data) {
      const timelogs = data?.issuable?.timelogs?.nodes || [];
      return timelogs.slice().sort((a, b) => new Date(a.spentAt) - new Date(b.spentAt));
    },
    formatDate(date) {
      return formatDate(date, TIME_DATE_FORMAT);
    },
    getSummary(summary, note) {
      return summary ?? note?.body;
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
    deleteTimelog(timelogId) {
      this.removingIds.push(timelogId);
      this.$apollo
        .mutate({
          mutation: deleteTimelogMutation,
          variables: { input: { id: timelogId } },
        })
        .then(({ data }) => {
          if (data.timelogDelete?.errors?.length) {
            throw new Error(data.timelogDelete.errors[0]);
          }
        })
        .catch((error) => {
          createAlert({
            message: s__('TimeTracking|An error occurred while removing the timelog.'),
            captureError: true,
            error,
          });
        })
        .finally(() => {
          this.removingIds.splice(this.removingIds.indexOf(timelogId), 1);
        });
    },
  },
  fields: [
    { key: 'spentAt', label: __('Spent at'), tdClass: 'gl-w-quarter' },
    { key: 'user', label: __('User') },
    { key: 'timeSpent', label: __('Time spent'), tdClass: 'gl-w-15' },
    { key: 'summary', label: __('Summary / note') },
    { key: 'actions', label: '', tdClass: 'gl-w-10' },
  ],
};
</script>

<template>
  <div>
    <div v-if="isLoading"><gl-loading-icon size="lg" /></div>
    <gl-table-lite v-else :items="report" :fields="$options.fields" foot-clone>
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

      <template #cell(summary)="{ item: { summary, note } }">
        <div>{{ getSummary(summary, note) }}</div>
      </template>
      <template #foot(summary)>&nbsp;</template>

      <template
        #cell(actions)="{
          item: {
            id,
            userPermissions: { adminTimelog },
          },
        }"
      >
        <div v-if="adminTimelog">
          <gl-button
            v-gl-tooltip="{ title: deleteButtonTooltip }"
            category="secondary"
            icon="remove"
            data-testid="deleteButton"
            :loading="isDeletingTimelog(id)"
            @click="deleteTimelog(id)"
          />
        </div>
      </template>
      <template #foot(actions)>&nbsp;</template>
    </gl-table-lite>
  </div>
</template>
