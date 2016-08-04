((w) => {
  w.DiscussionMixins = {
    computed: {
      discussionCount: function () {
        return Object.keys(this.discussions).length;
      },
      resolved: function () {
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
