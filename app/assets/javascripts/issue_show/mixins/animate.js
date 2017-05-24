export default {
  methods: {
    animateChange() {
      this.preAnimation = true;
      this.pulseAnimation = false;

      this.$nextTick(() => {
        this.preAnimation = false;
        this.pulseAnimation = true;
      });
    },
  },
};
