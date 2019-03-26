<script>
import icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    icon,
  },
  props: {
    isGroupOpen: {
      type: Boolean,
      required: true,
      default: false,
    },
  },
  computed: {
    iconClass() {
      return this.isGroupOpen ? 'angle-down' : 'angle-right';
    },
  },
};
</script>

<template>
  <span class="folder-caret append-right-4"> <icon :size="10" :name="iconClass" /> </span>
</template>
