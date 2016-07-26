(() => {
  JumpToDiscussion = Vue.extend({
    data: function () {
      return {
        discussions: CommentsStore.state,
      };
    },
    methods: {
      jumpToNextUnresolvedDiscussion: function () {
        let nextUnresolvedDiscussionId;

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

        $.scrollTo(`.${nextUnresolvedDiscussionId}`, {
          offset: -($('.navbar-gitlab').outerHeight() + $('.layout-nav').outerHeight())
        });
      },
    }
  });

  Vue.component('jump-to-discussion', JumpToDiscussion);
}());
