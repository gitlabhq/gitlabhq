<script>
import { GlAlert, GlBadge, GlButton, GlLoadingIcon, GlModal, GlTabs, GlTab } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { limitedCounterWithDelimiter } from '~/lib/utils/text_utility';
import { queryToObject } from '~/lib/utils/url_utility';
import deletePipelineScheduleMutation from '../graphql/mutations/delete_pipeline_schedule.mutation.graphql';
import getPipelineSchedulesQuery from '../graphql/queries/get_pipeline_schedules.query.graphql';
import PipelineSchedulesTable from './table/pipeline_schedules_table.vue';

export default {
  i18n: {
    schedulesFetchError: s__('PipelineSchedules|There was a problem fetching pipeline schedules.'),
    scheduleDeleteError: s__(
      'PipelineSchedules|There was a problem deleting the pipeline schedule.',
    ),
    newSchedule: s__('PipelineSchedules|New schedule'),
  },
  modal: {
    id: 'delete-pipeline-schedule-modal',
    deleteConfirmation: s__(
      'PipelineSchedules|Are you sure you want to delete this pipeline schedule?',
    ),
    actionPrimary: {
      text: s__('PipelineSchedules|Delete pipeline schedule'),
      attributes: [{ variant: 'danger' }],
    },
    actionCancel: {
      text: __('Cancel'),
      attributes: [],
    },
  },
  components: {
    GlAlert,
    GlBadge,
    GlButton,
    GlLoadingIcon,
    GlModal,
    GlTabs,
    GlTab,
    PipelineSchedulesTable,
  },
  inject: {
    fullPath: {
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

        return {
          list,
          count,
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
      errorMessage: '',
      scheduleToDeleteId: null,
      showModal: false,
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
    showDeleteModal(id) {
      this.showModal = true;
      this.scheduleToDeleteId = id;
    },
    hideModal() {
      this.showModal = false;
      this.scheduleToDeleteId = null;
    },
    async deleteSchedule() {
      try {
        const {
          data: {
            pipelineScheduleDelete: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: deletePipelineScheduleMutation,
          variables: { id: this.scheduleToDeleteId },
        });

        if (errors.length > 0) {
          throw new Error();
        } else {
          this.$apollo.queries.schedules.refetch();
        }
      } catch {
        this.reportError(this.$options.i18n.scheduleDeleteError);
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
    <gl-alert v-if="hasError" class="gl-mb-2" variant="danger" @dismiss="hasError = false">
      {{ errorMessage }}
    </gl-alert>

    <template v-else>
      <gl-tabs
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
            @showDeleteModal="showDeleteModal"
          />
        </gl-tab>

        <template #tabs-end>
          <gl-button variant="confirm" class="gl-ml-auto" data-testid="new-schedule-button">
            {{ $options.i18n.newSchedule }}
          </gl-button>
        </template>
      </gl-tabs>

      <gl-modal
        :visible="showModal"
        :title="$options.modal.actionPrimary.text"
        :modal-id="$options.modal.id"
        :action-primary="$options.modal.actionPrimary"
        :action-cancel="$options.modal.actionCancel"
        size="sm"
        @primary="deleteSchedule"
        @hide="hideModal"
      >
        {{ $options.modal.deleteConfirmation }}
      </gl-modal>
    </template>
  </div>
</template>
