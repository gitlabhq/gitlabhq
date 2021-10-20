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
    deletePath: {
      type: String,
      required: true,
    },
    modalType: {
      type: String,
      required: true,
    },
    userDeletionObstacles: {
      type: Array,
      required: true,
    },
  },
  computed: {
    modalAttributes() {
      return {
        'data-block-user-url': this.paths.block,
        'data-delete-user-url': this.deletePath,
        'data-gl-modal-action': this.modalType,
        'data-username': this.username,
        'data-user-deletion-obstacles': JSON.stringify(this.userDeletionObstacles),
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
