<script>
import SharedDeleteAction from './shared/shared_delete_action.vue';

export default {
  components: {
    SharedDeleteAction,
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
    oncallSchedules: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
};
</script>

<template>
  <shared-delete-action
    modal-type="delete"
    :username="username"
    :paths="paths"
    :oncall-schedules="oncallSchedules"
  >
    <slot></slot>
  </shared-delete-action>
</template>
