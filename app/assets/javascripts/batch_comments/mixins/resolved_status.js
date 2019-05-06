export default {
  computed: {
    resolveButtonTitle() {
      let title = 'Mark as resolved';

      if (this.resolvedBy) {
        title = `Resolved by ${this.resolvedBy.name}`;
      }

      return title;
    },
  },
};
