<script>
import { GlDropdown, GlDropdownItem, GlModal, GlModalDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import Tracking from '~/tracking';

export default {
  i18n: {
    deleteTask: s__('WorkItem|Delete task'),
  },
  components: {
    GlDropdown,
    GlDropdownItem,
    GlModal,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  mixins: [Tracking.mixin({ label: 'actions_menu' })],
  props: {
    workItemId: {
      type: String,
      required: false,
      default: null,
    },
    canDelete: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['deleteWorkItem'],
  methods: {
    handleDeleteWorkItem() {
      this.track('click_delete_work_item');
      this.$emit('deleteWorkItem');
    },
    handleCancelDeleteWorkItem({ trigger }) {
      if (trigger !== 'ok') {
        this.track('cancel_delete_work_item');
      }
    },
  },
};
</script>

<template>
  <div v-if="canDelete">
    <gl-dropdown
      icon="ellipsis_v"
      text-sr-only
      :text="__('More actions')"
      category="tertiary"
      no-caret
      right
    >
      <gl-dropdown-item v-gl-modal="'work-item-confirm-delete'">{{
        $options.i18n.deleteTask
      }}</gl-dropdown-item>
    </gl-dropdown>
    <gl-modal
      modal-id="work-item-confirm-delete"
      :title="$options.i18n.deleteWorkItem"
      :ok-title="$options.i18n.deleteWorkItem"
      ok-variant="danger"
      @ok="handleDeleteWorkItem"
      @hide="handleCancelDeleteWorkItem"
    >
      {{
        s__('WorkItem|Are you sure you want to delete the task? This action cannot be reversed.')
      }}
    </gl-modal>
  </div>
</template>
