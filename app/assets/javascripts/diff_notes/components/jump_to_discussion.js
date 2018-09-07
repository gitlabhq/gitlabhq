/* global CommentsStore */

import $ from 'jquery';
import Vue from 'vue';

import DiscussionMixins from '../mixins/discussion';

const JumpToDiscussion = Vue.extend({
  mixins: [DiscussionMixins],
  props: {
    discussionId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      discussions: CommentsStore.state,
      discussion: {},
    };
  },
  computed: {
    buttonText() {
      if (this.discussionId) {
        return 'Jump to next unresolved discussion';
      }

      return 'Jump to first unresolved discussion';
    },
    allResolved() {
      return this.unresolvedDiscussionCount === 0;
    },
    showButton() {
      if (this.discussionId) {
        if (this.unresolvedDiscussionCount > 1) {
          return true;
        }

        return this.discussionId !== this.lastResolvedId;
      }

      return this.unresolvedDiscussionCount >= 1;
    },
    lastResolvedId() {
      return Object.values(this.discussions).reduce((acc, discussion) => {
        if (!discussion.isResolved()) {
          return discussion.id;
        }

        return acc;
      }, '');
    },
  },
  created() {
    this.discussion = this.discussions[this.discussionId];
  },
  methods: {
    jumpToNextUnresolvedDiscussion() {
      let discussionsSelector;
      let discussionIdsInScope;
      let firstUnresolvedDiscussionId;
      let nextUnresolvedDiscussionId;
      let activeTab = window.mrTabs.currentAction;
      let hasDiscussionsToJumpTo = true;
      let jumpToFirstDiscussion = !this.discussionId;

      const discussionIdsForElements = function discussionIdsForElementsCallback(elements) {
        return elements
          .map(function discussionElementsMapCallback() {
            return $(this).attr('data-discussion-id');
          })
          .toArray();
      };

      const { discussions } = this;

      if (activeTab === 'diffs') {
        discussionsSelector = '.diffs .notes[data-discussion-id]';
        discussionIdsInScope = discussionIdsForElements($(discussionsSelector));

        let unresolvedDiscussionCount = 0;

        for (let i = 0; i < discussionIdsInScope.length; i += 1) {
          const discussionId = discussionIdsInScope[i];
          const discussion = discussions[discussionId];
          if (discussion && !discussion.isResolved()) {
            unresolvedDiscussionCount += 1;
          }
        }

        if (this.discussionId && !this.discussion.isResolved()) {
          // If this is the last unresolved discussion on the diffs tab,
          // there are no discussions to jump to.
          if (unresolvedDiscussionCount === 1) {
            hasDiscussionsToJumpTo = false;
          }
        } else if (unresolvedDiscussionCount === 0) {
          // If there are no unresolved discussions on the diffs tab at all,
          // there are no discussions to jump to.
          hasDiscussionsToJumpTo = false;
        }
      } else if (activeTab !== 'show') {
        // If we are on the commits or builds tabs,
        // there are no discussions to jump to.
        hasDiscussionsToJumpTo = false;
      }

      if (!hasDiscussionsToJumpTo) {
        // If there are no discussions to jump to on the current page,
        // switch to the notes tab and jump to the first disucssion there.
        window.mrTabs.activateTab('show');
        activeTab = 'show';
        jumpToFirstDiscussion = true;
      }

      if (activeTab === 'show') {
        discussionsSelector = '.discussion[data-discussion-id]';
        discussionIdsInScope = discussionIdsForElements($(discussionsSelector));
      }

      let currentDiscussionFound = false;
      discussionIdsInScope.forEach(discussionId => {
        const discussion = discussions[discussionId];

        if (!discussion) {
          // Discussions for comments on commits in this MR don't have a resolved status.
          return;
        }

        if (!firstUnresolvedDiscussionId && !discussion.isResolved()) {
          firstUnresolvedDiscussionId = discussionId;

          if (jumpToFirstDiscussion) {
            return;
          }
        }

        if (!jumpToFirstDiscussion) {
          if (currentDiscussionFound) {
            if (!discussion.isResolved()) {
              nextUnresolvedDiscussionId = discussionId;
              return;
            }

            return;
          }

          if (discussionId === this.discussionId) {
            currentDiscussionFound = true;
          }
        }
      });

      nextUnresolvedDiscussionId = nextUnresolvedDiscussionId || firstUnresolvedDiscussionId;

      if (!nextUnresolvedDiscussionId) {
        return;
      }

      let $target = $(`${discussionsSelector}[data-discussion-id="${nextUnresolvedDiscussionId}"]`);

      if (activeTab === 'show') {
        $target = $target.closest('.note-discussion');

        // If the next discussion is closed, toggle it open.
        if ($target.find('.js-toggle-content').is(':hidden')) {
          $target.find('.js-toggle-button i').trigger('click');
        }
      } else if (activeTab === 'diffs') {
        // Resolved discussions are hidden in the diffs tab by default.
        // If they are marked unresolved on the notes tab,
        // they will still be hidden on the diffs tab
        // When jumping between unresolved discussions on the diffs tab, we show them.
        $target.closest('.content').show();

        const $notesHolder = $target.closest('tr.notes_holder');

        // Image diff discussions does not use notes_holder
        // so we should keep original $target value in those cases
        if ($notesHolder.length > 0) {
          $target = $notesHolder;
        }

        $target.show();

        // If we are on the diffs tab, we don't scroll to the discussion itself, but to
        // 4 diff lines above it: the line the discussion was in response to + 3 context
        let prevEl;
        for (let i = 0; i < 4; i += 1) {
          prevEl = $target.prev();

          // If the discussion doesn't have 4 lines above it, we'll have to do with fewer.
          if (!prevEl.hasClass('line_holder')) {
            break;
          }

          $target = prevEl;
        }
      }

      $.scrollTo($target, {
        offset: -150,
      });
    },
  },
});

Vue.component('jump-to-discussion', JumpToDiscussion);
