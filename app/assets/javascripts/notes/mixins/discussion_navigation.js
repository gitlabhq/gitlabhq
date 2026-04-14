import { mapActions } from 'pinia';
import { contentTop } from '~/lib/utils/common_utils';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import { getScrollingElement } from '~/lib/utils/panels';
import { scrollPastCoveringElements } from '~/lib/utils/sticky';
import { withHiddenTooltips } from '~/lib/utils/viewport';

function isOverviewPage() {
  return window.mrTabs?.currentAction === 'show';
}

function isRapidDiffs() {
  return Boolean(document.querySelector('[data-rapid-diffs]'));
}

function getDiffsContainer() {
  if (isOverviewPage()) return '.tab-pane.notes';
  if (isRapidDiffs()) return '[data-rapid-diffs]';
  return '.diffs';
}

function getAllDiscussionElements() {
  const containerEl = getDiffsContainer();
  return Array.from(
    document.querySelectorAll(
      `${containerEl} [data-discussion-id][data-discussion-resolvable]:not([data-discussion-resolved])`,
    ),
  );
}

function getPanel() {
  return getScrollingElement(document.querySelector(getDiffsContainer()));
}

function isVisible(el) {
  if (typeof el.checkVisibility === 'function') return el.checkVisibility();
  return !el.closest('details:not([open])');
}

function getVisibleDiscussions() {
  return getAllDiscussionElements().filter(isVisible);
}

function scrollToDiscussion(target) {
  target.scrollIntoView(true);
  scrollPastCoveringElements(target);
}

function hasReachedPageEnd() {
  const panel = getPanel();
  return panel.scrollHeight <= Math.ceil(panel.scrollTop + panel.clientHeight);
}

function findNextClosestVisibleDiscussion(elements) {
  const offsetHeight = contentTop();
  let isActive;
  const index = elements.findIndex((element) => {
    const { y } = element.getBoundingClientRect();
    const visibleOffset = Math.ceil(y) - offsetHeight;
    isActive = visibleOffset < 2;
    return visibleOffset >= 0;
  });
  return { element: elements[index], index, isActive };
}

function isStickyOrFixed(el) {
  const { position } = getComputedStyle(el);
  return position === 'sticky' || position === 'fixed';
}

function hasNonStickyAncestor(el, stopAt) {
  let current = el;
  while (current && current !== stopAt && current !== document.body) {
    if (isStickyOrFixed(current)) return false;
    current = current.offsetParent;
  }
  return true;
}

function isScrolledTo(element) {
  return withHiddenTooltips(() => {
    const panel = getPanel();
    const panelRect = panel.getBoundingClientRect();
    const elRect = element.getBoundingClientRect();
    if (elRect.top < panelRect.top || elRect.top > panelRect.bottom) return false;
    const x = elRect.left + 1;
    const hitEl = document.elementFromPoint(x, elRect.top - 2);
    if (!hitEl || element.contains(hitEl) || hitEl.contains(element)) return false;
    return !hasNonStickyAncestor(hitEl, panel);
  });
}

function isSameRow(elA, elB) {
  if (!elA || !elB) return false;
  return Math.abs(elA.getBoundingClientRect().top - elB.getBoundingClientRect().top) < 5;
}

function findCurrentIndex(elements) {
  const panelTop = getPanel().getBoundingClientRect().top;
  return elements.findIndex((el) => el.getBoundingClientRect().top >= panelTop);
}

const strategies = {
  legacy: {
    getNext(elements) {
      const first = elements[0];
      if (hasReachedPageEnd()) return first;
      const { element: closest, index, isActive } = findNextClosestVisibleDiscussion(elements);
      if (closest && !isActive) return closest;
      const next = elements[index + 1];
      if (!closest || !next) return first;
      return next;
    },
    getPrevious(elements) {
      const last = elements[elements.length - 1];
      const { index } = findNextClosestVisibleDiscussion(elements);
      return elements[index - 1] || last;
    },
  },
  rapidDiffs: {
    getNext(elements) {
      const index = findCurrentIndex(elements);
      if (index === -1 || !isScrolledTo(elements[index])) {
        return elements[index] || elements[0];
      }
      let next = index + 1;
      while (next < elements.length && isSameRow(elements[index], elements[next])) {
        next += 1;
      }
      return elements[next] || elements[0];
    },
    getPrevious(elements) {
      const index = findCurrentIndex(elements);
      if (index <= 0 || !isScrolledTo(elements[index])) {
        return elements[elements.length - 1];
      }
      let prev = index - 1;
      while (prev >= 0 && isSameRow(elements[index], elements[prev])) {
        prev -= 1;
      }
      if (prev < 0) return elements[elements.length - 1];
      return elements[prev];
    },
  },
};

function getNavigationStrategy() {
  if (isOverviewPage()) return strategies.legacy;
  return isRapidDiffs() ? strategies.rapidDiffs : strategies.legacy;
}

function getNextDiscussion() {
  const elements = getVisibleDiscussions();
  if (!elements.length) return undefined;
  return getNavigationStrategy().getNext(elements);
}

function getPreviousDiscussion() {
  const elements = getVisibleDiscussions();
  if (!elements.length) return undefined;
  return getNavigationStrategy().getPrevious(elements);
}

function handleJumpForBothPages(getDiscussion, ctx) {
  const discussion = getDiscussion();

  if (!isOverviewPage() && !discussion) {
    window.mrTabs?.eventHub.$once('NotesAppReady', () => {
      handleJumpForBothPages(getDiscussion, ctx);
    });
    window.mrTabs?.setCurrentAction('show');
    window.mrTabs?.tabShown('show', undefined, false);
    return;
  }

  if (discussion) {
    const id = discussion.dataset.discussionId;
    ctx.expandDiscussion({ discussionId: id });
    scrollToDiscussion(discussion);
  }
}

export default {
  methods: {
    ...mapActions(useNotes, ['expandDiscussion', 'setCurrentDiscussionId']),
    ...mapActions(useLegacyDiffs, ['disableVirtualScroller']),

    async jumpToNextDiscussion() {
      await this.disableVirtualScroller();

      handleJumpForBothPages(getNextDiscussion, this);
    },

    async jumpToPreviousDiscussion() {
      await this.disableVirtualScroller();

      handleJumpForBothPages(getPreviousDiscussion, this);
    },

    jumpToFirstUnresolvedDiscussion() {
      this.setCurrentDiscussionId(null);
      this.jumpToNextDiscussion();
    },
  },
};
