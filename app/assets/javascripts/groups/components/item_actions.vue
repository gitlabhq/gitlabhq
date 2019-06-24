<script>
import tooltip from '~/vue_shared/directives/tooltip';
import icon from '~/vue_shared/components/icon.vue';
import eventHub from '../event_hub';
import { COMMON_STR } from '../constants';

export default {
  components: {
    icon,
  },
  directives: {
    tooltip,
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
      v-tooltip
      :href="group.leavePath"
      :title="leaveBtnTitle"
      :aria-label="leaveBtnTitle"
      data-container="body"
      data-placement="bottom"
      class="leave-group btn btn-xs no-expand"
      @click.prevent="onLeaveGroup"
    >
      <icon name="leave" css-classes="position-top-0" />
    </a>
    <a
      v-if="group.canEdit"
      v-tooltip
      :href="group.editPath"
      :title="editBtnTitle"
      :aria-label="editBtnTitle"
      data-container="body"
      data-placement="bottom"
      class="edit-group btn btn-xs no-expand"
    >
      <icon name="settings" css-classes="position-top-0" />
    </a>
  </div>
</template>
