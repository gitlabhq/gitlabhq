<script>
import { GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import DangerConfirmModal from '~/vue_shared/components/confirm_danger/confirm_danger_modal.vue';
import GroupListItemDelayedDeletionModalFooter from '~/vue_shared/components/groups_list/group_list_item_delayed_deletion_modal_footer.vue';

export default {
  name: 'GroupListItemDeleteModal',
  i18n: {
    immediatelyDeleteModalTitle: __('Delete group immediately?'),
    immediatelyDeleteModalBody: __(
      'This group is scheduled to be deleted on %{date}. You are about to delete this group, including its subgroups and projects, immediately. This action cannot be undone.',
    ),
  },
  components: {
    GlSprintf,
    DangerConfirmModal,
    GroupListItemDelayedDeletionModalFooter,
  },
  props: {
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
    modalId: {
      type: String,
      required: true,
    },
    phrase: {
      type: String,
      required: true,
    },
    confirmLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    group: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isMarkedForDeletion() {
      return Boolean(this.group.markedForDeletionOn);
    },
    groupWillBeImmediatelyDeleted() {
      return !this.group.isAdjournedDeletionEnabled || this.isMarkedForDeletion;
    },
    deleteModalOverride() {
      return this.groupWillBeImmediatelyDeleted
        ? this.$options.i18n.immediatelyDeleteModalTitle
        : undefined;
    },
  },
};
</script>

<template>
  <danger-confirm-modal
    :visible="visible"
    :modal-title="deleteModalOverride"
    :modal-id="modalId"
    :phrase="phrase"
    :confirm-loading="confirmLoading"
    @confirm.prevent="$emit('confirm', $event)"
    @change="$emit('change', $event)"
  >
    <template v-if="groupWillBeImmediatelyDeleted" #modal-body>
      <p>
        <gl-sprintf :message="$options.i18n.immediatelyDeleteModalBody">
          <template #date
            ><span class="gl-font-bold">{{ group.permanentDeletionDate }}</span></template
          >
        </gl-sprintf>
      </p>
    </template>
    <template #modal-footer
      ><group-list-item-delayed-deletion-modal-footer :group="group"
    /></template>
  </danger-confirm-modal>
</template>
