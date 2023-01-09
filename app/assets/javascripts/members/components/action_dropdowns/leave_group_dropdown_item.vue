<script>
import { GlDropdownItem, GlModalDirective } from '@gitlab/ui';
import { LEAVE_MODAL_ID } from '../../constants';
import LeaveModal from '../modals/leave_modal.vue';

export default {
  name: 'LeaveGroupDropdownItem',
  modalId: LEAVE_MODAL_ID,
  components: {
    GlDropdownItem,
    LeaveModal,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    member: {
      type: Object,
      required: true,
    },
    permissions: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <gl-dropdown-item v-gl-modal="$options.modalId">
    <span class="gl-text-red-500">
      <slot></slot>
    </span>
    <leave-modal :member="member" :permissions="permissions" />
  </gl-dropdown-item>
</template>
