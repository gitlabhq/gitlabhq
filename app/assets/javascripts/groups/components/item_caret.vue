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
  <span class="folder-caret">
    <icon
      :size="12"
      :name="iconClass"
    />
  </span>
</template>
