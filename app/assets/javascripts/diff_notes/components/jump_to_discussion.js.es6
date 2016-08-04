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
        let unresolvedIds = CommentsStore.unresolvedDiscussionIds(),
            nextUnresolvedDiscussionId;
        const activePage = $('.merge-request-tabs .active a').attr('data-action'),
              $diffDiscussions = $('.discussion').filter(function () {
                return unresolvedIds.indexOf($(this).attr('data-discussion-id')) !== -1;
              });

        unresolvedIds = unresolvedIds.sort(function (a, b) {
          return $diffDiscussions.index(`[data-discussion-id="${b}"]`) > $diffDiscussions.index(`[data-discussion-id="${a}"]`);
        });

        unresolvedIds.forEach(function (discussionId, i) {
          if (this.discussionId && discussionId === this.discussionId) {
            nextUnresolvedDiscussionId = unresolvedIds[i + 1];
            return;
          }
        }.bind(this));

        nextUnresolvedDiscussionId = nextUnresolvedDiscussionId || unresolvedIds[0];

        if (nextUnresolvedDiscussionId) {
          let selector = '.discussion';

          if (activePage === 'diffs' && $(`${selector}[data-discussion-id="${nextUnresolvedDiscussionId}"]`).length) {
            selector = '.diffs .notes';
          }

          $.scrollTo(`${selector}[data-discussion-id="${nextUnresolvedDiscussionId}"]`, {
            offset: -($('.navbar-gitlab').outerHeight() + $('.layout-nav').outerHeight())
          });
        }
      }
    }
  });

  Vue.component('jump-to-discussion', JumpToDiscussion);
})();
