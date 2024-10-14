<script>
import {
  GlButton,
  GlFormGroup,
  GlFormInput,
  GlLoadingIcon,
  GlKeysetPagination,
  GlDatepicker,
} from '@gitlab/ui';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { createAlert } from '~/alert';
import { formatTimeSpent } from '~/lib/utils/datetime_utility';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { s__ } from '~/locale';
import GroupSelect from '~/vue_shared/components/entity_select/group_select.vue';
import getTimelogsQuery from './queries/get_timelogs.query.graphql';
import TimelogsTable from './timelogs_table.vue';

const ENTRIES_PER_PAGE = 20;

// Define initial dates to current date and time
const INITIAL_TO_DATE_TIME = new Date(new Date().setHours(0, 0, 0, 0));
const INITIAL_FROM_DATE_TIME = new Date(new Date().setHours(0, 0, 0, 0));

// Set the initial 'from' date to 30 days before the current date
INITIAL_FROM_DATE_TIME.setDate(INITIAL_TO_DATE_TIME.getDate() - 30);

const GROUP_FILTER_API_PARAMS = {
  min_access_level: 20,
};

export default {
  components: {
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlLoadingIcon,
    GlKeysetPagination,
    GlDatepicker,
    GroupSelect,
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
    handleGroupSelected(group) {
      this.groupId = group?.id ? convertToGraphQLId(TYPENAME_GROUP, group.id) : null;
    },
  },
  i18n: {
    username: s__('TimeTrackingReport|Username'),
    from: s__('TimeTrackingReport|From the start of'),
    to: s__('TimeTrackingReport|To the end of'),
    runReport: s__('TimeTrackingReport|Run report'),
    totalTimeSpentText: s__('TimeTrackingReport|Total time spent: '),
  },
  GROUP_FILTER_API_PARAMS,
};
</script>

<template>
  <div class="gl-mt-5 gl-flex gl-flex-col gl-gap-5">
    <form class="gl-flex gl-flex-col gl-gap-3 md:gl-flex-row" @submit.prevent="runReport">
      <group-select
        class="gl-md-form-input-md gl-mb-0 gl-w-full"
        :label="__('Group')"
        input-name="group"
        input-id="group"
        :empty-text="__('Any')"
        block
        clearable
        :api-params="$options.GROUP_FILTER_API_PARAMS"
        @input="handleGroupSelected"
        @clear="handleGroupSelected"
      />
      <gl-form-group
        :label="$options.i18n.username"
        label-for="timelog-form-username"
        class="gl-md-form-input-md gl-mb-0 gl-w-full"
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
        class="gl-md-form-input-md gl-mb-0 gl-w-full"
      >
        <gl-datepicker
          v-model="timeSpentFrom"
          :target="null"
          show-clear-button
          autocomplete="off"
          data-testid="form-from-date"
          class="!gl-max-w-full"
          @clear="clearTimeSpentFromDate"
        />
      </gl-form-group>
      <gl-form-group
        key="time-spent-to"
        :label="$options.i18n.to"
        class="gl-md-form-input-md gl-mb-0 gl-w-full"
      >
        <gl-datepicker
          v-model="timeSpentTo"
          :target="null"
          show-clear-button
          autocomplete="off"
          data-testid="form-to-date"
          class="!gl-max-w-full"
          @clear="clearTimeSpentToDate"
        />
      </gl-form-group>
      <gl-button class="gl-w-full gl-self-end md:gl-w-auto" variant="confirm" @click="runReport">{{
        $options.i18n.runReport
      }}</gl-button>
    </form>
    <div v-if="!isLoading" data-testid="table-container" class="gl-flex gl-flex-col">
      <div v-if="report.length" class="gl-border-t gl-flex gl-gap-2 gl-py-4">
        <span class="gl-font-bold">{{ $options.i18n.totalTimeSpentText }}</span>
        <span data-testid="total-time-spent-container">{{ formattedTotalSpentTime }}</span>
      </div>

      <timelogs-table :limit-to-hours="limitToHours" :entries="report" />

      <gl-keyset-pagination
        v-if="showPagination"
        v-bind="pageInfo"
        class="gl-mt-3 gl-self-center"
        @prev="prevPage"
        @next="nextPage"
      />
    </div>
    <gl-loading-icon v-else size="lg" class="gl-mt-5" />
  </div>
</template>
