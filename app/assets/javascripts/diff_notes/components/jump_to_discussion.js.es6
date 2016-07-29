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
        const discussion = this.discussions[discussionId];
        return discussion.isResolved();
      },
      discussionsCount: function () {
        return Object.keys(this.discussions).length;
      },
      showButton: function () {
        return this.discussionsCount > 0 && (this.discussionsCount > 1 || !this.discussionId);
      }
    },
    methods: {
      jumpToNextUnresolvedDiscussion: function () {
        let nextUnresolvedDiscussionId,
            firstUnresolvedDiscussionId;

        if (!this.discussionId) {
          let i = 0;
          for (const discussionId in this.discussions) {
            const discussion = this.discussions[discussionId];
            const isResolved = discussion.isResolved();

            if (!firstUnresolvedDiscussionId && !isResolved) {
              firstUnresolvedDiscussionId = discussionId;
            }

            if (!isResolved) {
              nextUnresolvedDiscussionId = discussionId;
              break;
            }

            i++;
          }
        } else {
          let nextDiscussionId;
          const discussionKeys = Object.keys(this.discussions),
                indexOfDiscussion = discussionKeys.indexOf(this.discussionId);
                nextDiscussionIds = discussionKeys.splice(indexOfDiscussion);

          nextDiscussionIds.forEach((discussionId) => {
            if (discussionId !== this.discussionId) {
              const discussion = this.discussions[discussionId];

              if (!discussion.isResolved()) {
                nextDiscussionId = discussion.id;
              }
            }
          });

          if (nextDiscussionId) {
            nextUnresolvedDiscussionId = nextDiscussionId;
          } else {
            firstUnresolvedDiscussionId = discussionKeys[0];
          }
        }

        if (firstUnresolvedDiscussionId) {
          // Jump to first unresolved discussion
          nextUnresolvedDiscussionId = firstUnresolvedDiscussionId;
        }

        if (nextUnresolvedDiscussionId) {
          $('#notes').addClass('active');
          $('#commits, #builds, #diffs').removeClass('active');
          mrTabs.setCurrentAction('notes');

          $.scrollTo(`.discussion[data-discussion-id="${nextUnresolvedDiscussionId}"]`, {
            offset: -($('.navbar-gitlab').outerHeight() + $('.layout-nav').outerHeight())
          });
        }
      }
    }
  });

  Vue.component('jump-to-discussion', JumpToDiscussion);
})();
