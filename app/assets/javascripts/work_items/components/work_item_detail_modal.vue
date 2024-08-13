<script>
import { GlAlert, GlModal } from '@gitlab/ui';
import { s__ } from '~/locale';
import { scrollToTargetOnResize } from '~/lib/utils/resize_observer';
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
    workItemFullPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  emits: ['workItemDeleted', 'close', 'update-modal'],
  data() {
    return {
      error: undefined,
      updatedWorkItemIid: null,
      isModalShown: false,
      hasNotes: false,
    };
  },
  computed: {
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
      this.updatedWorkItemIid = workItem.iid;
      this.$emit('update-modal', $event, workItem);
    },
    onModalShow() {
      this.isModalShown = true;
    },
    updateHasNotes() {
      this.hasNotes = true;
    },
    openReportAbuseModal(reply) {
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
      :work-item-iid="displayedWorkItemIid"
      :modal-work-item-full-path="workItemFullPath"
      class="gl-p-5 -gl-mt-3 gl-bg-inherit gl-isolate"
      @close="hide"
      @deleteWorkItem="deleteWorkItem"
      @update-modal="updateModal"
      @has-notes="updateHasNotes"
      @openReportAbuse="openReportAbuseModal"
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
