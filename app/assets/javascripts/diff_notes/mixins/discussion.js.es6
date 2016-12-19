/* eslint-disable object-shorthand, func-names, guard-for-in, no-restricted-syntax, comma-dangle, no-plusplus, no-param-reassign, max-len */

((w) => {
  w.DiscussionMixins = {
    computed: {
      discussionCount: function () {
        return Object.keys(this.discussions).length;
      },
      resolvedDiscussionCount: function () {
        let resolvedCount = 0;

        for (const discussionId in this.discussions) {
          const discussion = this.discussions[discussionId];

          if (discussion.isResolved()) {
            resolvedCount++;
          }
        }

        return resolvedCount;
      },
      unresolvedDiscussionCount: function () {
        let unresolvedCount = 0;

        for (const discussionId in this.discussions) {
          const discussion = this.discussions[discussionId];

          if (!discussion.isResolved()) {
            unresolvedCount++;
          }
        }

        return unresolvedCount;
      }
    }
  };
})(window);
