<script>
import { GlButton, GlModalDirective, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import { LEAVE_MODAL_ID } from '../../constants';
import LeaveModal from '../modals/leave_modal.vue';

export default {
  name: 'LeaveButton',
  title: __('Leave'),
  modalId: LEAVE_MODAL_ID,
  components: {
    GlButton,
    LeaveModal,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  props: {
    member: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <gl-button
      v-gl-tooltip.hover
      v-gl-modal="$options.modalId"
      :title="$options.title"
      :aria-label="$options.title"
      icon="leave"
      variant="danger"
    />
    <leave-modal :member="member" />
  </div>
</template>
