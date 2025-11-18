<script>
import {
  GlAlert,
  GlBadge,
  GlButton,
  GlLoadingIcon,
  GlKeysetPagination,
  GlTabs,
  GlTab,
  GlSprintf,
  GlLink,
} from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__, sprintf } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import { limitedCounterWithDelimiter } from '~/lib/utils/text_utility';
import { queryToObject, updateHistory, setUrlParams } from '~/lib/utils/url_utility';
import { scrollToElement } from '~/lib/utils/scroll_utils';
import { reportToSentry } from '~/ci/utils';
import Tracking from '~/tracking';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import deletePipelineScheduleMutation from '../graphql/mutations/delete_pipeline_schedule.mutation.graphql';
import playPipelineScheduleMutation from '../graphql/mutations/play_pipeline_schedule.mutation.graphql';
import takeOwnershipMutation from '../graphql/mutations/take_ownership.mutation.graphql';
import getPipelineSchedulesQuery from '../graphql/queries/get_pipeline_schedules.query.graphql';
import pipelineScheduleStatusUpdatedSubscription from '../graphql/subscriptions/ci_pipeline_schedule_status_updated.subscription.graphql';
import {
  ALL_SCOPE,
  SCHEDULES_PER_PAGE,
  DEFAULT_SORT_VALUE,
  TABLE_SORT_STORAGE_KEY,
} from '../constants';
import { updateScheduleNodes } from '../utils';
import PipelineSchedulesTable from './table/pipeline_schedules_table.vue';
import TakeOwnershipModal from './take_ownership_modal.vue';
import DeletePipelineScheduleModal from './delete_pipeline_schedule_modal.vue';
import PipelineScheduleEmptyState from './pipeline_schedules_empty_state.vue';

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
    GlKeysetPagination,
    GlTabs,
    GlTab,
    GlSprintf,
    GlLink,
    LocalStorageSync,
    PipelineSchedulesTable,
    TakeOwnershipModal,
    PipelineScheduleEmptyState,
  },
  mixins: [Tracking.mixin()],
  inject: {
    projectPath: {
      default: '',
    },
    pipelinesPath: {
      default: '',
    },
    newSchedulePath: {
      default: '',
    },
    projectId: {
      default: '',
    },
  },
  apollo: {
    schedules: {
      query: getPipelineSchedulesQuery,
      variables() {
        const queryVariables = {
          projectPath: this.projectPath,
          // we need to ensure we send null to the API when
          // the scope is 'ALL'
          status: this.scope === ALL_SCOPE ? null : this.scope,
          sortValue: this.sortValue,
        };

        if (this.prevPageCursor) {
          queryVariables.prevPageCursor = this.prevPageCursor;
          queryVariables.first = null; // Explicitly set first to null when using last
          queryVariables.last = SCHEDULES_PER_PAGE;
          return queryVariables;
        }

        queryVariables.first = SCHEDULES_PER_PAGE;
        queryVariables.last = null; // Explicitly set last to null when using first
        queryVariables.nextPageCursor = this.nextPageCursor || '';
        queryVariables.prevPageCursor = '';

        return queryVariables;
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
      result({ data }) {
        // we use a manual subscribeToMore call due to issues with
        // the skip hook not working correctly for the subscription
        // and previousData object being an empty {} on init
        if (data?.project?.pipelineSchedules?.nodes?.length > 0 && !this.isSubscribed) {
          // Prevent duplicate subscriptions on refetch
          this.isSubscribed = true;

          this.$apollo.queries.schedules.subscribeToMore({
            document: pipelineScheduleStatusUpdatedSubscription,
            variables: {
              projectId: convertToGraphQLId(TYPENAME_PROJECT, this.projectId),
            },
            updateQuery(
              previousData,
              {
                subscriptionData: {
                  data: { ciPipelineScheduleStatusUpdated },
                },
              },
            ) {
              if (ciPipelineScheduleStatusUpdated) {
                const schedules = previousData?.project?.pipelineSchedules?.nodes || [];

                const updatedNodes = updateScheduleNodes(
                  schedules,
                  ciPipelineScheduleStatusUpdated,
                );

                return {
                  ...previousData,
                  project: {
                    ...previousData.project,
                    pipelineSchedules: {
                      ...previousData.project.pipelineSchedules,
                      nodes: updatedNodes,
                    },
                  },
                };
              }
              return previousData;
            },
          });
        }
      },
    },
  },
  data() {
    const queryParams = queryToObject(window.location.search);
    const { scope, page, prev, next, sort = DEFAULT_SORT_VALUE } = queryParams;

    const sortValue = sort;
    const sortDesc = sort.endsWith('_DESC');
    const sortBy = sortDesc ? sort.slice(0, -5) : sort;

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
      sortValue,
      sortBy,
      sortDesc,
      showDeleteModal: false,
      showTakeOwnershipModal: false,
      count: 0,
      isSubscribed: false,
      currentPage: parseInt(page, 10) || 1,
      prevPageCursor: prev || '',
      nextPageCursor: next || '',
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
      this.currentPage = 1;
      this.prevPageCursor = '';
      this.nextPageCursor = '';
      this.updateUrl();
    },
    fetchPipelineSchedulesByStatus(scope) {
      this.scope = scope;
      this.resetPagination();
      this.$apollo.queries.schedules.refetch();
    },
    handlePageChange(to) {
      const { startCursor, endCursor } = this.schedules.pageInfo;

      if (to === 'next') {
        this.prevPageCursor = '';
        this.nextPageCursor = endCursor;
        this.currentPage += 1;
      } else if (to === 'prev') {
        this.prevPageCursor = startCursor;
        this.nextPageCursor = '';
        this.currentPage -= 1;
      }

      this.track('click_navigation', { label: to });
      this.updateUrl();
      scrollToElement(this.$el);
    },
    onUpdateSorting(sortValue, sortBy, sortDesc) {
      this.sortValue = sortValue;
      this.sortBy = sortBy;
      this.sortDesc = sortDesc;

      this.resetPagination();
    },
    updateUrl() {
      const { href, search } = window.location;
      const queryParams = queryToObject(search, { gatherArrays: true });
      const {
        scope,
        currentPage: page = 1,
        prevPageCursor: prev,
        nextPageCursor: next,
        sortValue: sort,
      } = this;

      const params = { scope, page, prev, next, sort };
      for (const [param, value] of Object.entries(params)) {
        if (value && (param !== 'scope' || value !== ALL_SCOPE)) {
          queryParams[param] = value;
        } else {
          delete queryParams[param];
        }
      }

      // We want to replace the history state so that back button
      // correctly reloads the page with previous URL.
      updateHistory({
        url: setUrlParams(queryParams, { url: href, clearParams: true }),
        title: document.title,
        replace: true,
      });
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

          <div class="gl-flex gl-justify-center">
            <gl-keyset-pagination
              v-if="showPagination"
              v-bind="schedules.pageInfo"
              @prev="handlePageChange('prev')"
              @next="handlePageChange('next')"
            />
          </div>
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
