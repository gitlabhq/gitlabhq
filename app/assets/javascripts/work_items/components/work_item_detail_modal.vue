<script>
import { GlAlert, GlModal } from '@gitlab/ui';
import { s__ } from '~/locale';
import deleteWorkItemFromTaskMutation from '../graphql/delete_task_from_work_item.mutation.graphql';
import WorkItemDetail from './work_item_detail.vue';

export default {
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
              throw new Error(errors[0].message);
            }

            this.$emit('workItemDeleted', descriptionHtml);
            this.$refs.modal.hide();
          },
        )
        .catch((e) => {
          this.error =
            e.message ||
            s__('WorkItem|Something went wrong when deleting the work item. Please try again.');
        });
    },
    closeModal() {
      this.error = '';
      this.$emit('close');
    },
    setErrorMessage(message) {
      this.error = message;
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
    @hide="closeModal"
  >
    <gl-alert v-if="error" variant="danger" @dismiss="error = false">
      {{ error }}
    </gl-alert>

    <work-item-detail
      :work-item-parent-id="issueGid"
      :work-item-id="workItemId"
      class="gl-p-5 gl-mt-n3"
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
