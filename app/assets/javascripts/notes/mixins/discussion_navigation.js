import { mapGetters, mapActions, mapState } from 'vuex';
import { scrollToElementWithContext, scrollToElement, contentTop } from '~/lib/utils/common_utils';
import { updateHistory } from '~/lib/utils/url_utility';
import eventHub from '../event_hub';

/**
 * @param {string} selector
 * @returns {boolean}
 */
function scrollTo(selector, { withoutContext = false, offset = 0 } = {}) {
  const el = document.querySelector(selector);
  const scrollFunction = withoutContext ? scrollToElement : scrollToElementWithContext;

  if (el) {
    scrollFunction(el, {
      behavior: 'auto',
      offset,
    });
    return true;
  }

  return false;
}

function updateUrlWithNoteId(noteId) {
  const newHistoryEntry = {
    state: null,
    title: window.title,
    url: `#note_${noteId}`,
    replace: true,
  };

  if (noteId) {
    // Temporarily mask the ID to avoid the browser default
    //    scrolling taking over which is broken with virtual
    //    scrolling enabled.
    const note = document.querySelector(`#note_${noteId}`);
    note?.setAttribute('id', `masked::${note.id}`);

    // Update the hash now that the ID "doesn't exist" in the page
    updateHistory(newHistoryEntry);

    // Unmask the note's ID
    note?.setAttribute('id', `note_${noteId}`);
  }
}

/**
 * @param {object} self Component instance with mixin applied
 * @param {string} id Discussion id we are jumping to
 */
function diffsJump({ expandDiscussion }, id, firstNoteId) {
  const selector = `ul.notes[data-discussion-id="${id}"]`;

  eventHub.$once('scrollToDiscussion', () => {
    scrollTo(selector);
    // Wait for the discussion scroll before updating to the more specific ID
    setTimeout(() => updateUrlWithNoteId(firstNoteId), 0);
  });
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
  return scrollTo(selector, {
    withoutContext: true,
    offset: window.gon?.features?.movedMrSidebar ? -28 : 0,
  });
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
  const { id, diff_discussion: isDiffDiscussion, notes } = discussion;
  const firstNoteId = notes?.[0]?.id;
  if (id) {
    const activeTab = window.mrTabs.currentAction;

    if (activeTab === 'diffs' && isDiffDiscussion) {
      diffsJump(self, id, firstNoteId);
    } else {
      switchToDiscussionsTabAndJumpTo(self, id);
    }
  }
}

/**
 * @param {object} self Component instance with mixin applied
 * @param {function} fn Which function used to get the target discussion's id
 */
function handleDiscussionJump(self, fn) {
  const isDiffView = window.mrTabs.currentAction === 'diffs';
  const targetId = fn(self.currentDiscussionId, isDiffView);
  const discussion = self.getDiscussion(targetId);
  const discussionFilePath = discussion?.diff_file?.file_path;

  window.location.hash = '';

  if (discussionFilePath) {
    self.scrollToFile({
      path: discussionFilePath,
    });
  }

  self.$nextTick(() => {
    jumpToDiscussion(self, discussion);
    self.setCurrentDiscussionId(targetId);
  });
}

function getAllDiscussionElements() {
  return Array.from(
    document.querySelectorAll('[data-discussion-id]:not([data-discussion-resolved])'),
  );
}

function hasReachedPageEnd() {
  return document.body.scrollHeight <= Math.ceil(window.scrollY + window.innerHeight);
}

function findNextClosestVisibleDiscussion(discussionElements) {
  const offsetHeight = contentTop();
  let isActive;
  const index = discussionElements.findIndex((element) => {
    const { y } = element.getBoundingClientRect();
    const visibleHorizontalOffset = Math.ceil(y) - offsetHeight;
    // handle rect rounding errors
    isActive = visibleHorizontalOffset < 2;
    return visibleHorizontalOffset >= 0;
  });
  return [discussionElements[index], index, isActive];
}

function getNextDiscussion() {
  const discussionElements = getAllDiscussionElements();
  const firstDiscussion = discussionElements[0];
  if (hasReachedPageEnd()) {
    return firstDiscussion;
  }
  const [nextClosestDiscussion, index, isActive] = findNextClosestVisibleDiscussion(
    discussionElements,
  );
  if (nextClosestDiscussion && !isActive) {
    return nextClosestDiscussion;
  }
  const nextDiscussion = discussionElements[index + 1];
  if (!nextClosestDiscussion || !nextDiscussion) {
    return firstDiscussion;
  }
  return nextDiscussion;
}

function getPreviousDiscussion() {
  const discussionElements = getAllDiscussionElements();
  const lastDiscussion = discussionElements[discussionElements.length - 1];
  const [, index] = findNextClosestVisibleDiscussion(discussionElements);
  const previousDiscussion = discussionElements[index - 1];
  if (previousDiscussion) {
    return previousDiscussion;
  }
  return lastDiscussion;
}

function handleJumpForBothPages(getDiscussion, ctx, fn, scrollOptions) {
  if (window.mrTabs.currentAction !== 'show') {
    handleDiscussionJump(ctx, fn);
  } else {
    const discussion = getDiscussion();
    const id = discussion.dataset.discussionId;
    ctx.expandDiscussion({ discussionId: id });
    scrollToElement(discussion, scrollOptions);
  }
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

    jumpToNextDiscussion(scrollOptions) {
      handleJumpForBothPages(
        getNextDiscussion,
        this,
        this.nextUnresolvedDiscussionId,
        scrollOptions,
      );
    },

    jumpToPreviousDiscussion(scrollOptions) {
      handleJumpForBothPages(
        getPreviousDiscussion,
        this,
        this.previousUnresolvedDiscussionId,
        scrollOptions,
      );
    },

    jumpToFirstUnresolvedDiscussion() {
      this.setCurrentDiscussionId(null)
        .then(() => {
          this.jumpToNextDiscussion();
        })
        .catch(() => {});
    },
  },
};
