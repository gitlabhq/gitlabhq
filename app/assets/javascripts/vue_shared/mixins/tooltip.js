export default {
  mounted() {
    this.$nextTick(() => {
      $(this.$refs.tooltip).tooltip();
    });
  },

  updated() {
    this.$nextTick(() => {
      $(this.$refs.tooltip).tooltip('fixTitle');
    });
  },

  beforeDestroy() {
    $(this.$refs.tooltip).tooltip('destroy');
  },
};
