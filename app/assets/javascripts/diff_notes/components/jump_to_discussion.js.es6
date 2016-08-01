(() => {
  JumpToDiscussion = Vue.extend({
    props: {
      discussionId: String
    },
    data: function () {
      return {
        discussions: CommentsStore.state,
      };
    },
    computed: {
      allResolved: function () {
        const discussion = this.discussions[this.discussionId];

        if (discussion) {
          return discussion.isResolved();
        }
      },
      discussionsCount: function () {
        return CommentsStore.discussionCount();
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
      },
      showButton: function () {
        if (this.discussionId) {
          if (this.unresolvedDiscussionCount > 1) {
            return true;
          } else {
            return this.discussionId !== this.lastResolvedId();
          }
        } else {
          return this.unresolvedDiscussionCount >= 1;
        }
      }
    },
    methods: {
      lastResolvedId: function () {
        let lastId;
        for (const discussionId in this.discussions) {
          const discussion = this.discussions[discussionId];

          if (!discussion.isResolved()) {
            lastId = discussion.id;
          }
        }
        return lastId;
      },
      jumpToNextUnresolvedDiscussion: function () {
        let nextUnresolvedDiscussionId,
            firstUnresolvedDiscussionId,
            useNextDiscussionId = false,
            i = 0;

        for (const discussionId in this.discussions) {
          const discussion = this.discussions[discussionId];

          if (!discussion.isResolved()) {
            if (i === 0) {
              firstUnresolvedDiscussionId = discussion.id;
            }

            if (useNextDiscussionId) {
              nextUnresolvedDiscussionId = discussion.id;
              break;
            }

            if (this.discussionId && discussion.id === this.discussionId) {
              useNextDiscussionId = true;
            }

            i++;
          }
        }

        if (!nextUnresolvedDiscussionId && firstUnresolvedDiscussionId) {
          nextUnresolvedDiscussionId = firstUnresolvedDiscussionId;
        }

        if (nextUnresolvedDiscussionId) {
          mrTabs.activateTab('notes');

          $.scrollTo(`.discussion[data-discussion-id="${nextUnresolvedDiscussionId}"]`, {
            offset: -($('.navbar-gitlab').outerHeight() + $('.layout-nav').outerHeight())
          });
        }
      }
    }
  });

  Vue.component('jump-to-discussion', JumpToDiscussion);
})();
