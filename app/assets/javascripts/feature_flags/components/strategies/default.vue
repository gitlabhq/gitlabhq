<script>
export default {
  mounted() {
    this.$emit('change', { parameters: {} });
  },
  render() {
    return this.$slots.default;
  },
};
</script>
