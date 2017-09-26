<template>
  <div class="">
    <div class="media">
      <label class="media-body">Milestone</label>
      <a href="#" data-dropdown-trigger="#milestone-dropdown" ref="trigger">
        Edit
      </a>
    </div>
    <div class="droplab-dropdown">
      <div>
        Current value
      </div>
      <ul
        ref="list"
        class="dropdown-menu"
      >
        <slot name="items"></slot>
      </ul>
    </div>
  </div>
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
