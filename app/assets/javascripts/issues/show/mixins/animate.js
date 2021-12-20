export default {
  methods: {
    animateChange() {
      this.preAnimation = true;
      this.pulseAnimation = false;

      setTimeout(() => {
        this.preAnimation = false;
        this.pulseAnimation = true;
      });
    },
  },
};
