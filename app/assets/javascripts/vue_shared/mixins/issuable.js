export default {
  props: {
    issuableType: {
      required: true,
      type: String,
    },
  },

  computed: {
    issuableDisplayName() {
      return this.issuableType.replace(/_/g, ' ');
    },
  },
};
