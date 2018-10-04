/* eslint-disable object-shorthand, func-names, guard-for-in, no-restricted-syntax, comma-dangle, */

const DiscussionMixins = {
  computed: {
    discussionCount: function () {
      return Object.keys(this.discussions).length;
    },
    resolvedDiscussionCount: function () {
      let resolvedCount = 0;

      for (const discussionId in this.discussions) {
        const discussion = this.discussions[discussionId];

        if (discussion.isResolved()) {
          resolvedCount += 1;
        }
      }

      return resolvedCount;
    },
    unresolvedDiscussionCount: function () {
      let unresolvedCount = 0;

      for (const discussionId in this.discussions) {
        const discussion = this.discussions[discussionId];

        if (!discussion.isResolved()) {
          unresolvedCount += 1;
        }
      }

      return unresolvedCount;
    }
  }
};

export default DiscussionMixins;
