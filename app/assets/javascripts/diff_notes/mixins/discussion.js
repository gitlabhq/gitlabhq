/* eslint-disable object-shorthand, func-names, guard-for-in, no-restricted-syntax, comma-dangle, no-param-reassign, max-len */

window.DiscussionMixins = {
  computed: {
    discussionCount: function () {
      return Object.keys(this.discussions).length;
    },
    resolvedDiscussionCount: function () {
      let resolvedCount = 0;

      _.each(this.discussions, (discussion) => {
        if (discussion.resolved) {
          resolvedCount += 1;
        }
      });

      return resolvedCount;
    },
    unresolvedDiscussionCount: function () {
      let unresolvedCount = 0;

      _.each(this.discussions, (discussion) => {
        if (!discussion.resolved) {
          unresolvedCount += 1;
        }
      });

      return unresolvedCount;
    }
  }
};
