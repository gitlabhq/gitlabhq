<script>
export default {
  props: {
    selector: {
      type: String,
      required: true,
    },
  },
  mounted() {
    this.disposables = Array.from(document.querySelectorAll(this.selector)).flatMap((button) => {
      return Object.entries(this.$listeners).map(([key, value]) => {
        button.addEventListener(key, value);
        return () => {
          button.removeEventListener(key, value);
        };
      });
    });
  },
  destroyed() {
    this.disposables.forEach((x) => {
      x();
    });
  },
  render() {
    return this.$scopedSlots.default?.();
  },
};
</script>
