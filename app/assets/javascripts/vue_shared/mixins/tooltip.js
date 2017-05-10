export default {
  mounted() {
    $(this.$refs.tooltip).tooltip();
  },

  updated() {
    $(this.$refs.tooltip).tooltip('fixTitle');
  },
};
