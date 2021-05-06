<script>
export default {
  provide() {
    return {
      vuexModule: this.vuexModule,
    };
  },
  props: {
    vuexModule: {
      type: String,
      required: true,
    },
  },
  render() {
    return this.$slots.default;
  },
};
</script>
