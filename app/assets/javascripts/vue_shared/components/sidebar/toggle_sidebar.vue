<script>
  export default {
    name: 'ToggleSidebar',
    props: {
      collapsed: {
        type: Boolean,
        required: true,
      },
    },
    methods: {
      toggle() {
        this.$emit('toggle');
      },
    },
  };
</script>

<template>
  <button
    type="button"
    class="btn btn-blank gutter-toggle btn-sidebar-action"
    @click="toggle"
  >
    <i
      aria-label="toggle collapse"
      class="fa"
      :class="{
        'fa-angle-double-right': !collapsed,
        'fa-angle-double-left': collapsed
      }"
    >
    </i>
  </button>
</template>
