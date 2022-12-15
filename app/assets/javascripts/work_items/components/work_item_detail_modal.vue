<script>
import { GlAlert, GlModal } from '@gitlab/ui';
import { s__ } from '~/locale';
import deleteWorkItemFromTaskMutation from '../graphql/delete_task_from_work_item.mutation.graphql';
import deleteWorkItemMutation from '../graphql/delete_work_item.mutation.graphql';
import WorkItemDetail from './work_item_detail.vue';

export default {
  i18n: {
    errorMessage: s__('WorkItem|Something went wrong when deleting the task. Please try again.'),
  },
  components: {
    GlAlert,
    GlModal,
    WorkItemDetail,
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
  emits: ['workItemDeleted', 'close'],
  data() {
    return {
      error: undefined,
    };
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
      :work-item-id="workItemId"
      :work-item-iid="workItemIid"
      class="gl-p-5 gl-mt-n3"
      @close="hide"
      @deleteWorkItem="deleteWorkItem"
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
