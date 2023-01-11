<script>
import { GlAlert, GlModal } from '@gitlab/ui';
import { s__ } from '~/locale';
import deleteWorkItemFromTaskMutation from '../graphql/delete_task_from_work_item.mutation.graphql';
import deleteWorkItemMutation from '../graphql/delete_work_item.mutation.graphql';

export default {
  i18n: {
    errorMessage: s__('WorkItem|Something went wrong when deleting the task. Please try again.'),
  },
  components: {
    GlAlert,
    GlModal,
    WorkItemDetail: () => import('./work_item_detail.vue'),
  },
  props: {
    workItemId: {
      type: String,
      required: false,
      default: null,
    },
    workItemIid: {
      type: String,
      required: false,
      default: null,
    },
    issueGid: {
      type: String,
      required: false,
      default: '',
    },
    lockVersion: {
      type: Number,
      required: false,
      default: null,
    },
    lineNumberStart: {
      type: String,
      required: false,
      default: null,
    },
    lineNumberEnd: {
      type: String,
      required: false,
      default: null,
    },
  },
  emits: ['workItemDeleted', 'close', 'update-modal'],
  data() {
    return {
      error: undefined,
      updatedWorkItemId: null,
    };
  },
  computed: {
    displayedWorkItemId() {
      return this.updatedWorkItemId || this.workItemId;
    },
  },
  methods: {
    deleteWorkItem() {
      if (this.lockVersion != null && this.lineNumberStart && this.lineNumberEnd) {
        this.deleteWorkItemWithTaskData();
      } else {
        this.deleteWorkItemWithoutTaskData();
      }
    },
    deleteWorkItemWithTaskData() {
      this.$apollo
        .mutate({
          mutation: deleteWorkItemFromTaskMutation,
          variables: {
            input: {
              id: this.issueGid,
              lockVersion: this.lockVersion,
              taskData: {
                id: this.workItemId,
                lineNumberStart: Number(this.lineNumberStart),
                lineNumberEnd: Number(this.lineNumberEnd),
              },
            },
          },
        })
        .then(
          ({
            data: {
              workItemDeleteTask: {
                workItem: { descriptionHtml },
                errors,
              },
            },
          }) => {
            if (errors?.length) {
              throw new Error(errors[0]);
            }

            this.$emit('workItemDeleted', descriptionHtml);
            this.hide();
          },
        )
        .catch((error) => {
          this.setErrorMessage(error.message);
        });
    },
    deleteWorkItemWithoutTaskData() {
      this.$apollo
        .mutate({
          mutation: deleteWorkItemMutation,
          variables: { input: { id: this.workItemId } },
        })
        .then(({ data }) => {
          if (data.workItemDelete.errors?.length) {
            throw new Error(data.workItemDelete.errors[0]);
          }

          this.$emit('workItemDeleted', this.workItemId);
          this.hide();
        })
        .catch((error) => {
          this.setErrorMessage(error.message);
        });
    },
    closeModal() {
      this.updatedWorkItemId = null;
      this.error = '';
      this.$emit('close');
    },
    hide() {
      this.$refs.modal.hide();
    },
    setErrorMessage(message) {
      this.error = message || this.$options.i18n.errorMessage;
    },
    show() {
      this.$refs.modal.show();
    },
    updateModal($event, workItemId) {
      this.updatedWorkItemId = workItemId;
      this.$emit('update-modal', $event, workItemId);
    },
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    hide-footer
    size="lg"
    modal-id="work-item-detail-modal"
    header-class="gl-p-0 gl-pb-2!"
    scrollable
    @hide="closeModal"
  >
    <gl-alert v-if="error" variant="danger" @dismiss="error = false">
      {{ error }}
    </gl-alert>

    <work-item-detail
      is-modal
      :work-item-parent-id="issueGid"
      :work-item-id="displayedWorkItemId"
      :work-item-iid="workItemIid"
      class="gl-p-5 gl-mt-n3 gl-reset-bg gl-isolate"
      @close="hide"
      @deleteWorkItem="deleteWorkItem"
      @update-modal="updateModal"
    />
  </gl-modal>
</template>

<style>
/* hide the existing modal header
 */
#work-item-detail-modal .modal-header * {
  display: none;
}
</style>
