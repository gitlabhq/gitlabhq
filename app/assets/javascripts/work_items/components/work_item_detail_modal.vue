<script>
import { GlAlert, GlButton, GlModal } from '@gitlab/ui';
import WorkItemActions from './work_item_actions.vue';
import WorkItemDetail from './work_item_detail.vue';

export default {
  components: {
    GlAlert,
    GlButton,
    GlModal,
    WorkItemDetail,
    WorkItemActions,
  },
  props: {
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    visible: {
      type: Boolean,
      required: true,
    },
    workItemId: {
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
    handleWorkItemDeleted() {
      this.$emit('workItemDeleted');
      this.closeModal();
    },
    closeModal() {
      this.error = '';
      this.$emit('close');
    },
    setErrorMessage(message) {
      this.error = message;
    },
  },
};
</script>

<template>
  <gl-modal hide-footer modal-id="work-item-detail-modal" :visible="visible" @hide="closeModal">
    <template #modal-header>
      <div class="gl-w-full gl-display-flex gl-align-items-center gl-justify-content-end">
        <h2 class="modal-title gl-mr-auto">{{ s__('WorkItem|Work Item') }}</h2>
        <work-item-actions
          :work-item-id="workItemId"
          :can-update="canUpdate"
          @workItemDeleted="handleWorkItemDeleted"
          @error="setErrorMessage"
        />
        <gl-button category="tertiary" icon="close" :aria-label="__('Close')" @click="closeModal" />
      </div>
    </template>
    <gl-alert v-if="error" variant="danger" @dismiss="error = false">
      {{ error }}
    </gl-alert>

    <work-item-detail :work-item-id="workItemId" />
  </gl-modal>
</template>

<style>
/* hide the existing close button until we can do it
 * with https://gitlab.com/gitlab-org/gitlab-ui/-/merge_requests/2710
 */
#work-item-detail-modal .modal-header > .gl-button {
  display: none;
}
</style>
