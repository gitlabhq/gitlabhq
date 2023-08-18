<!-- eslint-disable vue/multi-word-component-names -->
<script>
export default {
  mounted() {
    this.$emit('change', { parameters: {} });
  },
  render() {
    return this.$scopedSlots.default?.();
  },
};
</script>
