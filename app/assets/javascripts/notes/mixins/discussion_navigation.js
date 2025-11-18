import { mapActions, mapState } from 'pinia';
import { contentTop } from '~/lib/utils/common_utils';
import { scrollToElement } from '~/lib/utils/scroll_utils';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';

function isOverviewPage() {
  return window.mrTabs?.currentAction === 'show';
}

function getAllDiscussionElements() {
  const containerEl = isOverviewPage() ? '.tab-pane.notes' : '.diffs';
  return Array.from(
    document.querySelectorAll(
      `${containerEl} div[data-discussion-id][data-discussion-resolvable]:not([data-discussion-resolved])`,
    ),
  );
}

function hasReachedPageEnd() {
  const panel = document.querySelector('.js-static-panel-inner');

  if (panel) {
    return panel.scrollHeight <= Math.ceil(panel.scrollTop + panel.clientHeight);
  }

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
  const [nextClosestDiscussion, index, isActive] =
    findNextClosestVisibleDiscussion(discussionElements);
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

// eslint-disable-next-line max-params
function handleJumpForBothPages(getDiscussion, ctx, fn, scrollOptions) {
  const discussion = getDiscussion();

  if (!isOverviewPage() && !discussion) {
    window.mrTabs?.eventHub.$once('NotesAppReady', () => {
      handleJumpForBothPages(getDiscussion, ctx, fn, scrollOptions);
    });
    window.mrTabs?.setCurrentAction('show');
    window.mrTabs?.tabShown('show', undefined, false);
    return;
  }

  if (discussion) {
    const id = discussion.dataset.discussionId;
    ctx.expandDiscussion({ discussionId: id });
    scrollToElement(discussion, scrollOptions);
  }
}

export default {
  computed: {
    ...mapState(useNotes, [
      'nextUnresolvedDiscussionId',
      'previousUnresolvedDiscussionId',
      'getDiscussion',
      'currentDiscussionId',
    ]),
  },
  methods: {
    ...mapActions(useNotes, ['expandDiscussion', 'setCurrentDiscussionId']),
    ...mapActions(useLegacyDiffs, ['scrollToFile', 'disableVirtualScroller']),

    async jumpToNextDiscussion(scrollOptions) {
      await this.disableVirtualScroller();

      handleJumpForBothPages(
        getNextDiscussion,
        this,
        this.nextUnresolvedDiscussionId,
        scrollOptions,
      );
    },

    async jumpToPreviousDiscussion(scrollOptions) {
      await this.disableVirtualScroller();

      handleJumpForBothPages(
        getPreviousDiscussion,
        this,
        this.previousUnresolvedDiscussionId,
        scrollOptions,
      );
    },

    jumpToFirstUnresolvedDiscussion() {
      this.setCurrentDiscussionId(null);
      this.jumpToNextDiscussion();
    },
  },
};
