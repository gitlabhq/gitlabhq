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
        let allResolved = true;
        for (const discussionId in this.discussions) {
          const discussion = this.discussions[discussionId];

          for (const noteId in discussion) {
            const note = discussion[noteId];

            if (!note.resolved) {
              allResolved = false;
            }
          }
        }

        return allResolved;
      }
    },
    methods: {
      jumpToNextUnresolvedDiscussion: function () {
        let nextUnresolvedDiscussionId;

        if (!this.discussionId) {
          for (const discussionId in this.discussions) {
            const discussion = this.discussions[discussionId];

            for (const noteId in discussion) {
              const note = discussion[noteId];

              if (!note.resolved) {
                nextUnresolvedDiscussionId = discussionId;
                break;
              }
            }

            if (nextUnresolvedDiscussionId) break;
          }
        } else {
          const discussionKeys = Object.keys(this.discussions),
                indexOfDiscussion = discussionKeys.indexOf(this.discussionId),
                nextDiscussionId = discussionKeys[indexOfDiscussion + 1];

          if (nextDiscussionId) {
            nextUnresolvedDiscussionId = nextDiscussionId;
          }
        }

        if (nextUnresolvedDiscussionId) {
          $.scrollTo(`.${nextUnresolvedDiscussionId}`, {
            offset: -($('.navbar-gitlab').outerHeight() + $('.layout-nav').outerHeight())
          });
        }
      }
    }
  });

  Vue.component('jump-to-discussion', JumpToDiscussion);
})();
