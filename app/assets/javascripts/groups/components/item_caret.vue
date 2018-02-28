<script>
export default {
  props: {
    isGroupOpen: {
      type: Boolean,
      required: true,
      default: false,
    },
  },
  computed: {
    iconClass() {
      return this.isGroupOpen ? 'fa-caret-down' : 'fa-caret-right';
    },
  },
};
</script>

<template>
  <span class="folder-caret">
    <i
      :class="iconClass"
      class="fa"
      aria-hidden="true"/>
  </span>
</template>
