/* eslint-disable guard-for-in, no-restricted-syntax, */

const DiscussionMixins = {
  computed: {
    discussionCount() {
      return Object.keys(this.discussions).length;
    },
    resolvedDiscussionCount() {
      let resolvedCount = 0;

      for (const discussionId in this.discussions) {
        const discussion = this.discussions[discussionId];

        if (discussion.isResolved()) {
          resolvedCount += 1;
        }
      }

      return resolvedCount;
    },
    unresolvedDiscussionCount() {
      let unresolvedCount = 0;

      for (const discussionId in this.discussions) {
        const discussion = this.discussions[discussionId];

        if (!discussion.isResolved()) {
          unresolvedCount += 1;
        }
      }

      return unresolvedCount;
    },
  },
};

export default DiscussionMixins;
