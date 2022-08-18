<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlDropdownDivider,
  GlModal,
  GlModalDirective,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import Tracking from '~/tracking';

export default {
  i18n: {
    deleteTask: s__('WorkItem|Delete task'),
    enableTaskConfidentiality: s__('WorkItem|Turn on confidentiality'),
    disableTaskConfidentiality: s__('WorkItem|Turn off confidentiality'),
  },
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
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
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    canDelete: {
      type: Boolean,
      required: false,
      default: false,
    },
    isConfidential: {
      type: Boolean,
      required: false,
      default: false,
    },
    isParentConfidential: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['deleteWorkItem', 'toggleWorkItemConfidentiality'],
  methods: {
    handleToggleWorkItemConfidentiality() {
      this.track('click_toggle_work_item_confidentiality');
      this.$emit('toggleWorkItemConfidentiality', !this.isConfidential);
    },
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
  <div>
    <gl-dropdown
      icon="ellipsis_v"
      text-sr-only
      :text="__('More actions')"
      category="tertiary"
      no-caret
      right
    >
      <template v-if="canUpdate && !isParentConfidential">
        <gl-dropdown-item
          data-testid="confidentiality-toggle-action"
          @click="handleToggleWorkItemConfidentiality"
          >{{
            isConfidential
              ? $options.i18n.disableTaskConfidentiality
              : $options.i18n.enableTaskConfidentiality
          }}</gl-dropdown-item
        >
        <gl-dropdown-divider v-if="canDelete" />
      </template>
      <gl-dropdown-item
        v-if="canDelete"
        v-gl-modal="'work-item-confirm-delete'"
        data-testid="delete-action"
        >{{ $options.i18n.deleteTask }}</gl-dropdown-item
      >
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
