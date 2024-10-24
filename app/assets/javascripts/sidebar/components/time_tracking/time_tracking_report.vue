<script>
import { GlLoadingIcon, GlTableLite, GlButton, GlTooltipDirective } from '@gitlab/ui';
import produce from 'immer';
import { createAlert } from '~/alert';
import { TYPENAME_ISSUE, TYPENAME_MERGE_REQUEST } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_ISSUE } from '~/issues/constants';
import {
  localeDateFormat,
  newDate,
  parseSeconds,
  stringifyTime,
} from '~/lib/utils/datetime_utility';
import { __, s__ } from '~/locale';
import { WIDGET_TYPE_TIME_TRACKING } from '~/work_items/constants';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import { timelogQueries } from '../../queries/constants';
import deleteTimelogMutation from '../../queries/delete_timelog.mutation.graphql';

export default {
  i18n: {
    deleteButtonText: s__('TimeTracking|Delete time spent'),
  },
  components: {
    GlLoadingIcon,
    GlTableLite,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    fullPath: {
      default: null,
    },
    issuableType: {
      default: null,
    },
  },
  props: {
    limitToHours: {
      type: Boolean,
      default: false,
      required: false,
    },
    issuableId: {
      type: String,
      required: false,
      default: '',
    },
    timelogs: {
      type: Array,
      required: false,
      default: undefined,
    },
    workItemIid: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      report: this.timelogs ?? [],
      removingIds: [],
    };
  },
  apollo: {
    report: {
      query() {
        return timelogQueries[this.issuableType].query;
      },
      variables() {
        const type = this.issuableType === TYPE_ISSUE ? TYPENAME_ISSUE : TYPENAME_MERGE_REQUEST;
        return {
          id: convertToGraphQLId(type, this.issuableId),
        };
      },
      update(data) {
        const timelogs = data?.issuable?.timelogs?.nodes || [];
        return timelogs.slice().sort((a, b) => new Date(a.spentAt) - new Date(b.spentAt));
      },
      error() {
        createAlert({ message: __('Something went wrong. Please try again.') });
      },
      skip() {
        return Boolean(this.timelogs);
      },
    },
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    workItem: {
      query: workItemByIidQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.workItemIid,
        };
      },
      update(data) {
        return data.workspace.workItem ?? {};
      },
      skip() {
        return !this.workItemIid;
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.report.loading || this.$apollo.queries.workItem.loading;
    },
    totalTimeSpent() {
      const seconds = this.report.reduce((acc, item) => acc + item.timeSpent, 0);
      return this.formatTimeSpent(seconds);
    },
  },
  watch: {
    timelogs(timelogs) {
      this.report = timelogs;
    },
  },
  methods: {
    isDeletingTimelog(timelogId) {
      return this.removingIds.includes(timelogId);
    },
    formatDate(date) {
      return localeDateFormat.asDateTimeFull.format(newDate(date));
    },
    formatShortDate(date) {
      return localeDateFormat.asDate.format(newDate(date));
    },
    getSummary(summary, note) {
      return summary ?? note?.body;
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
          update: (store) => {
            if (!this.workItemIid) {
              return;
            }
            store.updateQuery(
              {
                query: workItemByIidQuery,
                variables: { fullPath: this.fullPath, iid: this.workItemIid },
              },
              (sourceData) =>
                produce(sourceData, (draftState) => {
                  const timeTrackingWidget = draftState.workspace.workItem.widgets.find(
                    (widget) => widget.type === WIDGET_TYPE_TIME_TRACKING,
                  );
                  const timelogs = timeTrackingWidget.timelogs.nodes;
                  const index = timelogs.findIndex((timelog) => timelog.id === timelogId);

                  timeTrackingWidget.totalTimeSpent -= timelogs[index].timeSpent;
                  timelogs.splice(index, 1);
                }),
            );
          },
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
    { key: 'spentAt', label: __('Date'), tdClass: 'gl-w-1/4' },
    { key: 'timeSpent', label: __('Time spent'), tdClass: 'gl-w-15' },
    { key: 'user', label: __('User') },
    { key: 'summary', label: __('Summary') },
    { key: 'actions', label: '', tdClass: 'gl-w-10' },
  ],
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" size="lg" />
  <gl-table-lite v-else :items="report" :fields="$options.fields" foot-clone>
    <template #cell(spentAt)="{ item: { spentAt } }">
      <span v-gl-tooltip="formatDate(spentAt)">
        {{ formatShortDate(spentAt) }}
      </span>
    </template>
    <template #foot(spentAt)>&nbsp;</template>

    <template #cell(timeSpent)="{ item: { timeSpent } }">
      {{ formatTimeSpent(timeSpent) }}
    </template>
    <template #foot(timeSpent)>
      {{ totalTimeSpent }}
    </template>

    <template #cell(user)="{ item: { user } }">
      {{ user.name }}
    </template>
    <template #foot(user)>&nbsp;</template>

    <template #cell(summary)="{ item: { summary, note } }">
      {{ getSummary(summary, note) }}
    </template>
    <template #foot(summary)>&nbsp;</template>

    <template #cell(actions)="{ item: { id, userPermissions } }">
      <gl-button
        v-if="userPermissions.adminTimelog"
        v-gl-tooltip="$options.i18n.deleteButtonText"
        category="tertiary"
        icon="remove"
        variant="danger"
        :aria-label="$options.i18n.deleteButtonText"
        :loading="isDeletingTimelog(id)"
        @click="deleteTimelog(id)"
      />
    </template>
    <template #foot(actions)>&nbsp;</template>
  </gl-table-lite>
</template>
