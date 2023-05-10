<script>
import { GlAlert, GlModal } from '@gitlab/ui';
import { s__ } from '~/locale';
import { scrollToTargetOnResize } from '~/lib/utils/resize_observer';
import deleteWorkItemFromTaskMutation from '../graphql/delete_task_from_work_item.mutation.graphql';
import deleteWorkItemMutation from '../graphql/delete_work_item.mutation.graphql';

export default {
  WORK_ITEM_DETAIL_MODAL_ID: 'work-item-detail-modal',
  i18n: {
    errorMessage: s__('WorkItem|Something went wrong when deleting the task. Please try again.'),
    modalTitle: s__('WorkItem|Work item'),
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
      updatedWorkItemIid: null,
      isModalShown: false,
      hasNotes: false,
    };
  },
  computed: {
    displayedWorkItemId() {
      return this.updatedWorkItemId || this.workItemId;
    },
    displayedWorkItemIid() {
      return this.updatedWorkItemIid || this.workItemIid;
    },
  },
  watch: {
    hasNotes(newVal) {
      if (newVal && this.isModalShown) {
        scrollToTargetOnResize({ containerId: this.$options.WORK_ITEM_DETAIL_MODAL_ID });
      }
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
      this.updatedWorkItemIid = null;
      this.error = '';
      this.isModalShown = false;
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
    updateModal($event, workItem) {
      this.updatedWorkItemId = workItem.id;
      this.updatedWorkItemIid = workItem.iid;
      this.$emit('update-modal', $event, workItem);
    },
    onModalShow() {
      this.isModalShown = true;
    },
    updateHasNotes() {
      this.hasNotes = true;
    },
    openReportAbuseDrawer(reply) {
      this.hide();
      this.$emit('openReportAbuse', reply);
    },
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    static
    hide-footer
    size="lg"
    :modal-id="$options.WORK_ITEM_DETAIL_MODAL_ID"
    header-class="gl-p-0 gl-pb-2!"
    scrollable
    :title="$options.i18n.modalTitle"
    :data-testid="$options.WORK_ITEM_DETAIL_MODAL_ID"
    @hide="closeModal"
    @shown="onModalShow"
  >
    <gl-alert v-if="error" variant="danger" @dismiss="error = false">
      {{ error }}
    </gl-alert>

    <work-item-detail
      is-modal
      :work-item-parent-id="issueGid"
      :work-item-id="displayedWorkItemId"
      :work-item-iid="displayedWorkItemIid"
      class="gl-p-5 gl-mt-n3 gl-reset-bg gl-isolation-isolate"
      @close="hide"
      @deleteWorkItem="deleteWorkItem"
      @update-modal="updateModal"
      @has-notes="updateHasNotes"
      @openReportAbuse="openReportAbuseDrawer"
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
