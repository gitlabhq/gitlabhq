export default {
  computed: {
    avatarSizeStylesMap() {
      return {
        width: `${this.size}px`,
        height: `${this.size}px`,
      };
    },
    avatarSizeClass() {
      return `s${this.size}`;
    },
  },
};
