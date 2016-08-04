(() => {
  JumpToDiscussion = Vue.extend({
    mixins: [DiscussionMixins],
    props: {
      discussionId: String
    },
    data: function () {
      return {
        discussions: CommentsStore.state,
      };
    },
    computed: {
      discussion: function () {
        return this.discussions[this.discussionId];
      },
      allResolved: function () {
        if (this.discussion) {
          return this.unresolvedDiscussionCount === 0;
        }
      },
      showButton: function () {
        if (this.discussionId) {
          if (this.unresolvedDiscussionCount > 1) {
            return true;
          } else {
            return this.discussionId !== this.lastResolvedId;
          }
        } else {
          return this.unresolvedDiscussionCount >= 1;
        }
      },
      lastResolvedId: function () {
        let lastId;
        for (const discussionId in this.discussions) {
          const discussion = this.discussions[discussionId];

          if (!discussion.isResolved()) {
            lastId = discussion.id;
          }
        }
        return lastId;
      }
    },
    methods: {
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

        nextUnresolvedDiscussionId = nextUnresolvedDiscussionId || firstUnresolvedDiscussionId

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
