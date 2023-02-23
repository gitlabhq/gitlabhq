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
import {
  sprintfWorkItem,
  I18N_WORK_ITEM_DELETE,
  I18N_WORK_ITEM_ARE_YOU_SURE_DELETE,
} from '../constants';

export default {
  i18n: {
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
    workItemType: {
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
  computed: {
    i18n() {
      return {
        deleteWorkItem: sprintfWorkItem(I18N_WORK_ITEM_DELETE, this.workItemType),
        areYouSureDelete: sprintfWorkItem(I18N_WORK_ITEM_ARE_YOU_SURE_DELETE, this.workItemType),
      };
    },
  },
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
      data-testid="work-item-actions-dropdown"
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
        variant="danger"
        >{{ i18n.deleteWorkItem }}</gl-dropdown-item
      >
    </gl-dropdown>
    <gl-modal
      modal-id="work-item-confirm-delete"
      :title="i18n.deleteWorkItem"
      :ok-title="i18n.deleteWorkItem"
      ok-variant="danger"
      @ok="handleDeleteWorkItem"
      @hide="handleCancelDeleteWorkItem"
    >
      {{ i18n.areYouSureDelete }}
    </gl-modal>
  </div>
</template>
