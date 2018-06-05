<script>
export default {
  props: {
    title: {
      type: String,
      required: false,
      default: '',
    },
    active: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      // props can't be updated, so we map it to data where we can
      localActive: this.active,
    };
  },
  watch: {
    active() {
      this.localActive = this.active;
    },
  },
  created() {
    this.isTab = true;
  },
};
</script>

<template>
  <div
    class="tab-pane"
    :class="{
      active: localActive
    }"
    role="tabpanel"
  >
    <slot></slot>
  </div>
</template>
