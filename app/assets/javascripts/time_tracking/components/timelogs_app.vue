<script>
import {
  GlButton,
  GlFormGroup,
  GlFormInput,
  GlLoadingIcon,
  GlKeysetPagination,
  GlDatepicker,
} from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { createAlert } from '~/alert';
import { formatTimeSpent } from '~/lib/utils/datetime_utility';
import { s__ } from '~/locale';
import getTimelogsQuery from './queries/get_timelogs.query.graphql';
import TimelogsTable from './timelogs_table.vue';

const ENTRIES_PER_PAGE = 20;

// Define initial dates to current date and time
const INITIAL_TO_DATE_TIME = new Date(new Date().setHours(0, 0, 0, 0));
const INITIAL_FROM_DATE_TIME = new Date(new Date().setHours(0, 0, 0, 0));

// Set the initial 'from' date to 30 days before the current date
INITIAL_FROM_DATE_TIME.setDate(INITIAL_TO_DATE_TIME.getDate() - 30);

export default {
  components: {
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlLoadingIcon,
    GlKeysetPagination,
    GlDatepicker,
    TimelogsTable,
  },
  props: {
    limitToHours: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      projectId: null,
      groupId: null,
      username: null,
      timeSpentFrom: INITIAL_FROM_DATE_TIME,
      timeSpentTo: INITIAL_TO_DATE_TIME,
      cursor: {
        first: ENTRIES_PER_PAGE,
        after: null,
        last: null,
        before: null,
      },
      queryVariables: {
        startTime: INITIAL_FROM_DATE_TIME,
        endTime: INITIAL_TO_DATE_TIME,
        projectId: null,
        groupId: null,
        username: null,
      },
      pageInfo: {},
      report: [],
      totalSpentTime: 0,
    };
  },
  apollo: {
    report: {
      query: getTimelogsQuery,
      variables() {
        return {
          ...this.queryVariables,
          ...this.cursor,
        };
      },
      update({ timelogs: { nodes = [], pageInfo = {}, totalSpentTime = 0 } = {} }) {
        this.pageInfo = pageInfo;
        this.totalSpentTime = totalSpentTime;
        return nodes;
      },
      error(error) {
        createAlert({ message: s__('TimeTrackingReport|Something went wrong. Please try again.') });
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.report.loading;
    },
    showPagination() {
      return this.pageInfo?.hasPreviousPage || this.pageInfo?.hasNextPage;
    },
    formattedTotalSpentTime() {
      return formatTimeSpent(this.totalSpentTime, this.limitToHours);
    },
  },
  methods: {
    nullIfBlank(value) {
      return value === '' ? null : value;
    },
    runReport() {
      this.cursor = {
        first: ENTRIES_PER_PAGE,
        after: null,
        last: null,
        before: null,
      };

      const { timeSpentTo } = this;

      if (timeSpentTo) {
        timeSpentTo.setDate(timeSpentTo.getDate() + 1);
      }

      this.queryVariables = {
        startTime: this.nullIfBlank(this.timeSpentFrom),
        endTime: this.nullIfBlank(timeSpentTo),
        projectId: this.nullIfBlank(this.projectId),
        groupId: this.nullIfBlank(this.groupId),
        username: this.nullIfBlank(this.username),
      };
    },
    nextPage(item) {
      this.cursor = {
        first: ENTRIES_PER_PAGE,
        after: item,
        last: null,
        before: null,
      };
    },
    prevPage(item) {
      this.cursor = {
        first: null,
        after: null,
        last: ENTRIES_PER_PAGE,
        before: item,
      };
    },
    clearTimeSpentFromDate() {
      this.timeSpentFrom = null;
    },
    clearTimeSpentToDate() {
      this.timeSpentTo = null;
    },
  },
  i18n: {
    username: s__('TimeTrackingReport|Username'),
    from: s__('TimeTrackingReport|From the start of'),
    to: s__('TimeTrackingReport|To the end of'),
    runReport: s__('TimeTrackingReport|Run report'),
    totalTimeSpentText: s__('TimeTrackingReport|Total time spent: '),
  },
};
</script>

<template>
  <div class="gl-display-flex gl-flex-direction-column gl-gap-5 gl-mt-5">
    <form
      class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row gl-gap-3"
      @submit.prevent="runReport"
    >
      <gl-form-group
        :label="$options.i18n.username"
        label-for="timelog-form-username"
        class="gl-mb-0 gl-md-form-input-md gl-w-full"
      >
        <gl-form-input
          id="timelog-form-username"
          v-model="username"
          data-testid="form-username"
          class="gl-w-full"
        />
      </gl-form-group>
      <gl-form-group
        key="time-spent-from"
        :label="$options.i18n.from"
        class="gl-mb-0 gl-md-form-input-md gl-w-full"
      >
        <gl-datepicker
          v-model="timeSpentFrom"
          :target="null"
          show-clear-button
          autocomplete="off"
          data-testid="form-from-date"
          class="gl-max-w-full!"
          @clear="clearTimeSpentFromDate"
        />
      </gl-form-group>
      <gl-form-group
        key="time-spent-to"
        :label="$options.i18n.to"
        class="gl-mb-0 gl-md-form-input-md gl-w-full"
      >
        <gl-datepicker
          v-model="timeSpentTo"
          :target="null"
          show-clear-button
          autocomplete="off"
          data-testid="form-to-date"
          class="gl-max-w-full!"
          @clear="clearTimeSpentToDate"
        />
      </gl-form-group>
      <gl-button
        class="gl-align-self-end gl-w-full gl-md-w-auto"
        variant="confirm"
        @click="runReport"
        >{{ $options.i18n.runReport }}</gl-button
      >
    </form>
    <div
      v-if="!isLoading"
      data-testid="table-container"
      class="gl-display-flex gl-flex-direction-column"
    >
      <div v-if="report.length" class="gl-display-flex gl-gap-2 gl-border-t gl-py-4">
        <span class="gl-font-weight-bold">{{ $options.i18n.totalTimeSpentText }}</span>
        <span data-testid="total-time-spent-container">{{ formattedTotalSpentTime }}</span>
      </div>

      <timelogs-table :limit-to-hours="limitToHours" :entries="report" />

      <gl-keyset-pagination
        v-if="showPagination"
        v-bind="pageInfo"
        class="gl-mt-3 gl-align-self-center"
        @prev="prevPage"
        @next="nextPage"
      />
    </div>
    <gl-loading-icon v-else size="lg" class="gl-mt-5" />
  </div>
</template>
