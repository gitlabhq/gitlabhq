<script>
import { GlTooltipDirective, GlButton, GlModalDirective } from '@gitlab/ui';
import eventHub from '../event_hub';
import { COMMON_STR } from '../constants';

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  props: {
    parentGroup: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    group: {
      type: Object,
      required: true,
    },
    action: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    leaveBtnTitle() {
      return COMMON_STR.LEAVE_BTN_TITLE;
    },
    editBtnTitle() {
      return COMMON_STR.EDIT_BTN_TITLE;
    },
  },
  methods: {
    onLeaveGroup() {
      eventHub.$emit(`${this.action}showLeaveGroupModal`, this.group, this.parentGroup);
    },
  },
};
</script>

<template>
  <div class="controls d-flex justify-content-end">
    <gl-button
      v-if="group.canLeave"
      v-gl-tooltip.top
      v-gl-modal.leave-group-modal
      :title="leaveBtnTitle"
      :aria-label="leaveBtnTitle"
      data-testid="leave-group-btn"
      size="small"
      icon="leave"
      class="leave-group gl-ml-3"
      @click.stop="onLeaveGroup"
    />
    <gl-button
      v-if="group.canEdit"
      v-gl-tooltip.top
      :href="group.editPath"
      :title="editBtnTitle"
      :aria-label="editBtnTitle"
      data-testid="edit-group-btn"
      size="small"
      icon="pencil"
      class="edit-group gl-ml-3"
    />
  </div>
</template>
