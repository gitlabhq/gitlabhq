import { mapGetters, mapActions, mapState } from 'vuex';
import { scrollToElementWithContext, scrollToElement } from '~/lib/utils/common_utils';
import eventHub from '../event_hub';

/**
 * @param {string} selector
 * @returns {boolean}
 */
function scrollTo(selector, { withoutContext = false } = {}) {
  const el = document.querySelector(selector);
  const scrollFunction = withoutContext ? scrollToElement : scrollToElementWithContext;

  if (el) {
    scrollFunction(el);
    return true;
  }

  return false;
}

/**
 * @param {object} self Component instance with mixin applied
 * @param {string} id Discussion id we are jumping to
 */
function diffsJump({ expandDiscussion }, id) {
  const selector = `ul.notes[data-discussion-id="${id}"]`;
  eventHub.$once('scrollToDiscussion', () => scrollTo(selector));
  expandDiscussion({ discussionId: id });
}

/**
 * @param {object} self Component instance with mixin applied
 * @param {string} id Discussion id we are jumping to
 * @returns {boolean}
 */
function discussionJump({ expandDiscussion }, id) {
  const selector = `div.discussion[data-discussion-id="${id}"]`;
  expandDiscussion({ discussionId: id });
  return scrollTo(selector, { withoutContext: true });
}

/**
 * @param {object} self Component instance with mixin applied
 * @param {string} id Discussion id we are jumping to
 */
function switchToDiscussionsTabAndJumpTo(self, id) {
  window.mrTabs.eventHub.$once('MergeRequestTabChange', () => {
    setTimeout(() => discussionJump(self, id), 0);
  });

  window.mrTabs.tabShown('show');
}

/**
 * @param {object} self Component instance with mixin applied
 * @param {object} discussion Discussion we are jumping to
 */
function jumpToDiscussion(self, discussion) {
  const { id, diff_discussion: isDiffDiscussion } = discussion;
  if (id) {
    const activeTab = window.mrTabs.currentAction;

    if (activeTab === 'diffs' && isDiffDiscussion) {
      diffsJump(self, id);
    } else if (activeTab === 'show') {
      discussionJump(self, id);
    } else {
      switchToDiscussionsTabAndJumpTo(self, id);
    }
  }
}

/**
 * @param {object} self Component instance with mixin applied
 * @param {function} fn Which function used to get the target discussion's id
 * @param {string} [discussionId=this.currentDiscussionId] Current discussion id, will be null if discussions have not been traversed yet
 */
function handleDiscussionJump(self, fn, discussionId = self.currentDiscussionId) {
  const isDiffView = window.mrTabs.currentAction === 'diffs';
  const targetId = fn(discussionId, isDiffView);
  const discussion = self.getDiscussion(targetId);
  const discussionFilePath = discussion?.diff_file?.file_path;

  if (discussionFilePath) {
    self.scrollToFile(discussionFilePath);
  }

  self.$nextTick(() => {
    jumpToDiscussion(self, discussion);
    self.setCurrentDiscussionId(targetId);
  });
}

export default {
  computed: {
    ...mapGetters([
      'nextUnresolvedDiscussionId',
      'previousUnresolvedDiscussionId',
      'getDiscussion',
    ]),
    ...mapState({
      currentDiscussionId: (state) => state.notes.currentDiscussionId,
    }),
  },
  methods: {
    ...mapActions(['expandDiscussion', 'setCurrentDiscussionId']),
    ...mapActions('diffs', ['scrollToFile']),

    jumpToNextDiscussion() {
      handleDiscussionJump(this, this.nextUnresolvedDiscussionId);
    },

    jumpToPreviousDiscussion() {
      handleDiscussionJump(this, this.previousUnresolvedDiscussionId);
    },

    jumpToFirstUnresolvedDiscussion() {
      this.setCurrentDiscussionId(null)
        .then(() => {
          this.jumpToNextDiscussion();
        })
        .catch(() => {});
    },

    /**
     * Go to the next discussion from the given discussionId
     * @param {String} discussionId The id we are jumping from
     */
    jumpToNextRelativeDiscussion(discussionId) {
      handleDiscussionJump(this, this.nextUnresolvedDiscussionId, discussionId);
    },
  },
};
