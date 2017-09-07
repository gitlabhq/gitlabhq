export default {
  methods: {
    issuableDisplayName(issuableType) {
      return issuableType.replace(/_/, ' ');
    },
  },
};
