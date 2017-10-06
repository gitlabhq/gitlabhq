export default {
  methods: {
    issuableDisplayName(issuableType) {
      const displayName = issuableType.replace(/_/, ' ');

      return this.__ ? this.__(displayName) : displayName;
    },
  },
};
