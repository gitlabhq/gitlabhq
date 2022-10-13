<script>
import { GlAlert, GlLoadingIcon, GlModal } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import deletePipelineScheduleMutation from '../graphql/mutations/delete_pipeline_schedule.mutation.graphql';
import getPipelineSchedulesQuery from '../graphql/queries/get_pipeline_schedules.query.graphql';
import PipelineSchedulesTable from './table/pipeline_schedules_table.vue';

export default {
  i18n: {
    schedulesFetchError: s__('PipelineSchedules|There was a problem fetching pipeline schedules.'),
    scheduleDeleteError: s__(
      'PipelineSchedules|There was a problem deleting the pipeline schedule.',
    ),
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
    GlLoadingIcon,
    GlModal,
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
        };
      },
      update({ project }) {
        return project?.pipelineSchedules?.nodes || [];
      },
      error() {
        this.reportError(this.$options.i18n.schedulesFetchError);
      },
    },
  },
  data() {
    return {
      schedules: [],
      hasError: false,
      errorMessage: '',
      scheduleToDeleteId: null,
      showModal: false,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.schedules.loading;
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
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="hasError" class="gl-mb-2" variant="danger" @dismiss="hasError = false">
      {{ errorMessage }}
    </gl-alert>

    <gl-loading-icon v-if="isLoading" size="lg" />

    <!-- Tabs will be addressed in #371989 -->

    <template v-else>
      <pipeline-schedules-table :schedules="schedules" @showDeleteModal="showDeleteModal" />

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
