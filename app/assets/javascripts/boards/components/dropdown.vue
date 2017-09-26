<template>
  <ul
    ref="list"
    class="dropdown-menu"
  >
    <slot name="items"></slot>
  </ul>
</template>

<script>
import DropLab from '~/droplab/drop_lab';

export default {
  props: {
  },
  data() {
    return {
      loading: false,
    };
  },
  mounted() {
    this.droplab = new DropLab();
    this.droplab.init(this.$refs.trigger, this.$refs.list);
  },
};
</script>
