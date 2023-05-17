<script>
import {
  GlAlert,
  GlBadge,
  GlButton,
  GlLoadingIcon,
  GlTabs,
  GlTab,
  GlSprintf,
  GlLink,
} from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { limitedCounterWithDelimiter } from '~/lib/utils/text_utility';
import { queryToObject } from '~/lib/utils/url_utility';
import deletePipelineScheduleMutation from '../graphql/mutations/delete_pipeline_schedule.mutation.graphql';
import playPipelineScheduleMutation from '../graphql/mutations/play_pipeline_schedule.mutation.graphql';
import takeOwnershipMutation from '../graphql/mutations/take_ownership.mutation.graphql';
import getPipelineSchedulesQuery from '../graphql/queries/get_pipeline_schedules.query.graphql';
import PipelineSchedulesTable from './table/pipeline_schedules_table.vue';
import TakeOwnershipModal from './take_ownership_modal.vue';
import DeletePipelineScheduleModal from './delete_pipeline_schedule_modal.vue';
import PipelineScheduleEmptyState from './pipeline_schedules_empty_state.vue';

export default {
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
  },
  components: {
    DeletePipelineScheduleModal,
    GlAlert,
    GlBadge,
    GlButton,
    GlLoadingIcon,
    GlTabs,
    GlTab,
    GlSprintf,
    GlLink,
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
  },
  apollo: {
    schedules: {
      query: getPipelineSchedulesQuery,
      variables() {
        return {
          projectPath: this.fullPath,
          status: this.scope,
        };
      },
      update(data) {
        const { pipelineSchedules: { nodes: list = [], count } = {} } = data.project || {};
        const currentUser = data.currentUser || {};

        return {
          list,
          count,
          currentUser,
        };
      },
      error() {
        this.reportError(this.$options.i18n.schedulesFetchError);
      },
    },
  },
  data() {
    const { scope } = queryToObject(window.location.search);
    return {
      schedules: {
        list: [],
      },
      scope,
      hasError: false,
      playSuccess: false,
      errorMessage: '',
      scheduleId: null,
      showDeleteModal: false,
      showTakeOwnershipModal: false,
      count: 0,
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
          scope: null,
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
  },
  watch: {
    // this watcher ensures that the count on the all tab
    //  is not updated when switching to other tabs
    schedulesCount(newCount) {
      if (!this.scope) {
        this.count = newCount;
      }
    },
  },
  methods: {
    reportError(error) {
      this.hasError = true;
      this.errorMessage = error;
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
      } catch {
        this.reportError(this.$options.i18n.scheduleDeleteError);
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
      } catch {
        this.reportError(this.$options.i18n.takeOwnershipError);
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
      } catch {
        this.playSuccess = false;
        this.reportError(this.$options.i18n.schedulePlayError);
      }
    },
    fetchPipelineSchedulesByStatus(scope) {
      this.scope = scope;
      this.$apollo.queries.schedules.refetch();
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
          <gl-link :href="pipelinesPath" class="gl-text-decoration-none!">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>

    <gl-tabs
      v-if="isLoading || count > 0"
      sync-active-tab-with-query-params
      query-param-name="scope"
      nav-class="gl-flex-grow-1 gl-align-items-center"
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

            <gl-badge v-else-if="tab.count" size="sm" class="gl-tab-counter-badge">
              {{ tab.count }}
            </gl-badge>
          </template>
        </template>

        <gl-loading-icon v-if="isLoading" size="lg" />
        <pipeline-schedules-table
          v-else
          :schedules="schedules.list"
          :current-user="schedules.currentUser"
          @showTakeOwnershipModal="setTakeOwnershipModal"
          @showDeleteModal="setDeleteModal"
          @playPipelineSchedule="playPipelineSchedule"
        />
      </gl-tab>

      <template #tabs-end>
        <gl-button variant="confirm" class="gl-ml-auto" data-testid="new-schedule-button">
          {{ $options.i18n.newSchedule }}
        </gl-button>
      </template>
    </gl-tabs>

    <pipeline-schedule-empty-state v-else-if="!isLoading && count === 0" />

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
