<script>
import { GlDropdownItem } from '@gitlab/ui';

export default {
  components: {
    GlDropdownItem,
  },
  props: {
    username: {
      type: String,
      required: true,
    },
    paths: {
      type: Object,
      required: true,
    },
    modalType: {
      type: String,
      required: true,
    },
    oncallSchedules: {
      type: Array,
      required: true,
    },
  },
  computed: {
    modalAttributes() {
      return {
        'data-block-user-url': this.paths.block,
        'data-delete-user-url': this.paths.delete,
        'data-gl-modal-action': this.modalType,
        'data-username': this.username,
        'data-oncall-schedules': JSON.stringify(this.oncallSchedules),
      };
    },
  },
};
</script>

<template>
  <div class="js-delete-user-modal-button" v-bind="{ ...modalAttributes }">
    <gl-dropdown-item>
      <span class="gl-text-red-500">
        <slot></slot>
      </span>
    </gl-dropdown-item>
  </div>
</template>
