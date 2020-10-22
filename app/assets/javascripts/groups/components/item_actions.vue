<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import eventHub from '../event_hub';
import { COMMON_STR } from '../constants';

export default {
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
    <a
      v-if="group.canLeave"
      v-gl-tooltip.top
      :href="group.leavePath"
      :title="leaveBtnTitle"
      :aria-label="leaveBtnTitle"
      data-testid="leave-group-btn"
      class="leave-group btn btn-xs no-expand gl-text-gray-500 gl-ml-5"
      @click.prevent="onLeaveGroup"
    >
      <gl-icon name="leave" class="position-top-0" />
    </a>
    <a
      v-if="group.canEdit"
      v-gl-tooltip.top
      :href="group.editPath"
      :title="editBtnTitle"
      :aria-label="editBtnTitle"
      data-testid="edit-group-btn"
      class="edit-group btn btn-xs no-expand gl-text-gray-500 gl-ml-5"
    >
      <gl-icon name="settings" class="position-top-0 align-middle" />
    </a>
  </div>
</template>
