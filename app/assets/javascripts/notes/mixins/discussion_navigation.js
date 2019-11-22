import { scrollToElement } from '~/lib/utils/common_utils';
import eventHub from '../../notes/event_hub';

export default {
  methods: {
    diffsJump(id) {
      const selector = `ul.notes[data-discussion-id="${id}"]`;

      eventHub.$once('scrollToDiscussion', () => {
        const el = document.querySelector(selector);

        if (el) {
          scrollToElement(el);

          return true;
        }

        return false;
      });

      this.expandDiscussion({ discussionId: id });
    },
    discussionJump(id) {
      const selector = `div.discussion[data-discussion-id="${id}"]`;

      const el = document.querySelector(selector);

      this.expandDiscussion({ discussionId: id });

      if (el) {
        scrollToElement(el);

        return true;
      }

      return false;
    },

    switchToDiscussionsTabAndJumpTo(id) {
      window.mrTabs.eventHub.$once('MergeRequestTabChange', () => {
        setTimeout(() => this.discussionJump(id), 0);
      });

      window.mrTabs.tabShown('show');
    },

    jumpToDiscussion(discussion) {
      const { id, diff_discussion: isDiffDiscussion } = discussion;
      if (id) {
        const activeTab = window.mrTabs.currentAction;

        if (activeTab === 'diffs' && isDiffDiscussion) {
          this.diffsJump(id);
        } else if (activeTab === 'show') {
          this.discussionJump(id);
        } else {
          this.switchToDiscussionsTabAndJumpTo(id);
        }
      }
    },
  },
};
