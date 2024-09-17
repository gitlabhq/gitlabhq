<script>
import {
  GlAlert,
  GlBadge,
  GlButton,
  GlLoadingIcon,
  GlPagination,
  GlTabs,
  GlTab,
  GlSprintf,
  GlLink,
} from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__, sprintf } from '~/locale';
import { limitedCounterWithDelimiter } from '~/lib/utils/text_utility';
import { queryToObject } from '~/lib/utils/url_utility';
import { reportToSentry } from '~/ci/utils';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import deletePipelineScheduleMutation from '../graphql/mutations/delete_pipeline_schedule.mutation.graphql';
import playPipelineScheduleMutation from '../graphql/mutations/play_pipeline_schedule.mutation.graphql';
import takeOwnershipMutation from '../graphql/mutations/take_ownership.mutation.graphql';
import getPipelineSchedulesQuery from '../graphql/queries/get_pipeline_schedules.query.graphql';
import {
  ALL_SCOPE,
  SCHEDULES_PER_PAGE,
  DEFAULT_SORT_VALUE,
  TABLE_SORT_STORAGE_KEY,
} from '../constants';
import PipelineSchedulesTable from './table/pipeline_schedules_table.vue';
import TakeOwnershipModal from './take_ownership_modal.vue';
import DeletePipelineScheduleModal from './delete_pipeline_schedule_modal.vue';
import PipelineScheduleEmptyState from './pipeline_schedules_empty_state.vue';

const defaultPagination = {
  first: SCHEDULES_PER_PAGE,
  last: null,
  prevPageCursor: '',
  nextPageCursor: '',
  currentPage: 1,
};

export default {
  name: 'PipelineSchedules',
  i18n: {
    schedulesFetchError: s__('PipelineSchedules|There was a problem fetching pipeline schedules.'),
    scheduleDeleteError: s__(
      'PipelineSchedules|There was a problem deleting the pipeline schedule.',
    ),
    schedulePlayError: s__('PipelineSchedules|There was a problem playing the pipeline schedule.'),
    takeOwnershipError: s__(
      'PipelineSchedules|There was a problem taking ownership of the pipeline schedule.',
    ),
    newSchedule: s__('PipelineSchedules|New schedule'),
    deleteSuccess: s__('PipelineSchedules|Pipeline schedule successfully deleted.'),
    playSuccess: s__(
      'PipelineSchedules|Successfully scheduled a pipeline to run. Go to the %{linkStart}Pipelines page%{linkEnd} for details. ',
    ),
    planLimitReachedMsg: s__(
      'PipelineSchedules|You have exceeded the maximum number of pipeline schedules for your plan. To create a new schedule, either increase your plan limit or delete an existing schedule.',
    ),
    planLimitReachedBtnText: s__('PipelineSchedules|Explore plan limits'),
  },
  sortStorageKey: TABLE_SORT_STORAGE_KEY,
  docsLink: helpPagePath('administration/instance_limits', {
    anchor: 'number-of-pipeline-schedules',
  }),
  components: {
    DeletePipelineScheduleModal,
    GlAlert,
    GlBadge,
    GlButton,
    GlLoadingIcon,
    GlPagination,
    GlTabs,
    GlTab,
    GlSprintf,
    GlLink,
    LocalStorageSync,
    PipelineSchedulesTable,
    TakeOwnershipModal,
    PipelineScheduleEmptyState,
  },
  inject: {
    fullPath: {
      default: '',
    },
    pipelinesPath: {
      default: '',
    },
    newSchedulePath: {
      default: '',
    },
  },
  apollo: {
    schedules: {
      query: getPipelineSchedulesQuery,
      variables() {
        return {
          projectPath: this.fullPath,
          // we need to ensure we send null to the API when
          // the scope is 'ALL'
          status: this.scope === ALL_SCOPE ? null : this.scope,
          sortValue: this.sortValue,
          first: this.pagination.first,
          last: this.pagination.last,
          prevPageCursor: this.pagination.prevPageCursor,
          nextPageCursor: this.pagination.nextPageCursor,
        };
      },
      update(data) {
        const {
          pipelineSchedules: { nodes: list = [], count, pageInfo = {} } = {},
          projectPlanLimits: { ciPipelineSchedules } = {},
        } = data.project || {};
        const currentUser = data.currentUser || {};

        return {
          list,
          count,
          currentUser,
          pageInfo,
          planLimit: ciPipelineSchedules,
        };
      },
      error(error) {
        this.reportError(this.$options.i18n.schedulesFetchError, error);
      },
    },
  },
  data() {
    const { scope } = queryToObject(window.location.search);
    return {
      schedules: {
        list: [],
        currentUser: {},
      },
      scope,
      hasError: false,
      playSuccess: false,
      errorMessage: '',
      scheduleId: null,
      sortValue: DEFAULT_SORT_VALUE,
      sortBy: 'ID',
      sortDesc: true,
      showDeleteModal: false,
      showTakeOwnershipModal: false,
      count: 0,
      pagination: {
        ...defaultPagination,
      },
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.schedules.loading;
    },
    schedulesCount() {
      return this.schedules.count;
    },
    tabs() {
      return [
        {
          text: s__('PipelineSchedules|All'),
          count: limitedCounterWithDelimiter(this.count),
          scope: ALL_SCOPE,
          showBadge: true,
          attrs: { 'data-testid': 'pipeline-schedules-all-tab' },
        },
        {
          text: s__('PipelineSchedules|Active'),
          scope: 'ACTIVE',
          showBadge: false,
          attrs: { 'data-testid': 'pipeline-schedules-active-tab' },
        },
        {
          text: s__('PipelineSchedules|Inactive'),
          scope: 'INACTIVE',
          showBadge: false,
          attrs: { 'data-testid': 'pipeline-schedules-inactive-tab' },
        },
      ];
    },
    onAllTab() {
      // scope is undefined on first load, scope is only defined
      // after tab switching
      return this.scope === ALL_SCOPE || !this.scope;
    },
    showEmptyState() {
      return !this.isLoading && this.schedulesCount === 0 && this.onAllTab;
    },
    showPagination() {
      return this.schedules?.pageInfo?.hasNextPage || this.schedules?.pageInfo?.hasPreviousPage;
    },
    prevPage() {
      return Number(this.schedules?.pageInfo?.hasPreviousPage);
    },
    nextPage() {
      return Number(this.schedules?.pageInfo?.hasNextPage);
    },
    // if limit is null, then user does not have access to create schedule
    hasNoAccess() {
      return this.schedules?.planLimit === null;
    },
    // if limit is 0, then schedule creation is unlimited
    hasUnlimitedSchedules() {
      return this.schedules?.planLimit === 0;
    },
    // if limit is x, then schedule creation is limited
    hasReachedPlanLimit() {
      return this.schedules?.count >= this.schedules?.planLimit;
    },
    shouldShowLimitReachedAlert() {
      return !this.hasUnlimitedSchedules && this.hasReachedPlanLimit && !this.hasNoAccess;
    },
    shouldDisableNewScheduleBtn() {
      return (this.hasReachedPlanLimit || this.hasNoAccess) && !this.hasUnlimitedSchedules;
    },
    sortingState: {
      get() {
        return { sortValue: this.sortValue, sortBy: this.sortBy, sortDesc: this.sortDesc };
      },
      set(values) {
        this.sortValue = values.sortValue;
        this.sortBy = values.sortBy;
        this.sortDesc = values.sortDesc;
      },
    },
  },
  watch: {
    // this watcher ensures that the count on the all tab
    //  is not updated when switching to other tabs
    schedulesCount(newCount) {
      if (!this.scope || this.scope === ALL_SCOPE) {
        this.count = newCount;
      }
    },
  },
  methods: {
    reportError(errorMessage, error) {
      this.hasError = true;
      this.errorMessage = errorMessage;

      reportToSentry(this.$options.name, error);
    },
    setDeleteModal(id) {
      this.showDeleteModal = true;
      this.scheduleId = id;
    },
    setTakeOwnershipModal(id) {
      this.showTakeOwnershipModal = true;
      this.scheduleId = id;
    },
    hideModal() {
      this.showDeleteModal = false;
      this.showTakeOwnershipModal = false;
      this.scheduleId = null;
    },
    async deleteSchedule() {
      try {
        const {
          data: {
            pipelineScheduleDelete: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: deletePipelineScheduleMutation,
          variables: { id: this.scheduleId },
        });

        if (errors.length > 0) {
          throw new Error();
        } else {
          this.$apollo.queries.schedules.refetch();
          this.$toast.show(this.$options.i18n.deleteSuccess);
        }
      } catch (error) {
        this.reportError(this.$options.i18n.scheduleDeleteError, error);
      }
    },
    async takeOwnership() {
      try {
        const {
          data: {
            pipelineScheduleTakeOwnership: { pipelineSchedule, errors },
          },
        } = await this.$apollo.mutate({
          mutation: takeOwnershipMutation,
          variables: { id: this.scheduleId },
        });

        if (errors.length > 0) {
          throw new Error();
        } else {
          this.$apollo.queries.schedules.refetch();

          if (pipelineSchedule?.owner?.name) {
            const toastMsg = sprintf(
              s__('PipelineSchedules|Successfully taken ownership from %{owner}.'),
              {
                owner: pipelineSchedule.owner.name,
              },
            );

            this.$toast.show(toastMsg);
          }
        }
      } catch (error) {
        this.reportError(this.$options.i18n.takeOwnershipError, error);
      }
    },
    async playPipelineSchedule(id) {
      try {
        const {
          data: {
            pipelineSchedulePlay: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: playPipelineScheduleMutation,
          variables: { id },
        });

        if (errors.length > 0) {
          throw new Error();
        } else {
          this.playSuccess = true;
        }
      } catch (error) {
        this.playSuccess = false;

        this.reportError(this.$options.i18n.schedulePlayError, error);
      }
    },
    resetPagination() {
      this.pagination = {
        ...defaultPagination,
      };
    },
    fetchPipelineSchedulesByStatus(scope) {
      this.scope = scope;
      this.resetPagination();
      this.$apollo.queries.schedules.refetch();
    },
    handlePageChange(page) {
      const { startCursor, endCursor } = this.schedules.pageInfo;

      if (page > this.pagination.currentPage) {
        this.pagination = {
          first: SCHEDULES_PER_PAGE,
          last: null,
          prevPageCursor: '',
          nextPageCursor: endCursor,
          currentPage: page,
        };
      } else {
        this.pagination = {
          last: SCHEDULES_PER_PAGE,
          first: null,
          prevPageCursor: startCursor,
          currentPage: page,
        };
      }
    },
    onUpdateSorting(sortValue, sortBy, sortDesc) {
      this.sortValue = sortValue;
      this.sortBy = sortBy;
      this.sortDesc = sortDesc;

      this.resetPagination();
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="hasError" class="gl-my-3" variant="danger" @dismiss="hasError = false">
      {{ errorMessage }}
    </gl-alert>

    <gl-alert v-if="playSuccess" class="gl-my-3" variant="info" @dismiss="playSuccess = false">
      <gl-sprintf :message="$options.i18n.playSuccess">
        <template #link="{ content }">
          <gl-link :href="pipelinesPath" class="!gl-no-underline">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>

    <gl-alert
      v-if="shouldShowLimitReachedAlert"
      class="gl-my-3"
      variant="warning"
      :dismissible="false"
      data-testid="plan-limit-reached-alert"
    >
      <p>{{ $options.i18n.planLimitReachedMsg }}</p>

      <gl-button :href="$options.docsLink" variant="confirm">
        {{ $options.i18n.planLimitReachedBtnText }}
      </gl-button>
    </gl-alert>

    <local-storage-sync v-model="sortingState" :storage-key="$options.sortStorageKey" />

    <pipeline-schedule-empty-state v-if="showEmptyState" />

    <gl-tabs
      v-else
      sync-active-tab-with-query-params
      query-param-name="scope"
      nav-class="gl-grow gl-items-center gl-mt-2"
    >
      <gl-tab
        v-for="tab in tabs"
        :key="tab.text"
        :title-link-attributes="tab.attrs"
        :query-param-value="tab.scope"
        @click="fetchPipelineSchedulesByStatus(tab.scope)"
      >
        <template #title>
          <span>{{ tab.text }}</span>

          <template v-if="tab.showBadge">
            <gl-loading-icon v-if="tab.scope === scope && isLoading" class="gl-ml-2" />

            <gl-badge v-else-if="tab.count" class="gl-tab-counter-badge">
              {{ tab.count }}
            </gl-badge>
          </template>
        </template>

        <gl-loading-icon v-if="isLoading" size="lg" />

        <template v-else>
          <pipeline-schedules-table
            :schedules="schedules.list"
            :current-user="schedules.currentUser"
            :sort-by="sortBy"
            :sort-desc="sortDesc"
            @showTakeOwnershipModal="setTakeOwnershipModal"
            @showDeleteModal="setDeleteModal"
            @playPipelineSchedule="playPipelineSchedule"
            @update-sorting="onUpdateSorting"
          />

          <gl-pagination
            v-if="showPagination"
            :value="pagination.currentPage"
            :prev-page="prevPage"
            :next-page="nextPage"
            align="center"
            class="gl-mt-5"
            @input="handlePageChange"
          />
        </template>
      </gl-tab>

      <template #tabs-end>
        <gl-button
          v-if="!isLoading"
          :href="newSchedulePath"
          class="gl-ml-auto"
          variant="confirm"
          :disabled="shouldDisableNewScheduleBtn"
          data-testid="new-schedule-button"
        >
          {{ $options.i18n.newSchedule }}
        </gl-button>
      </template>
    </gl-tabs>

    <take-ownership-modal
      :visible="showTakeOwnershipModal"
      @takeOwnership="takeOwnership"
      @hideModal="hideModal"
    />

    <delete-pipeline-schedule-modal
      :visible="showDeleteModal"
      @deleteSchedule="deleteSchedule"
      @hideModal="hideModal"
    />
  </div>
</template>
