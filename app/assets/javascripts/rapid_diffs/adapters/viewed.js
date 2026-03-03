import { pinia } from '~/pinia/instance';
import {
  MOUNTED,
  COLLAPSE_FILE,
  COLLAPSE_FILE_BY_USER,
  EXPAND_FILE,
} from '~/rapid_diffs/adapter_events';
import { useCodeReview } from '~/diffs/stores/code_review';

function getViewedStyleElement(id) {
  return document.querySelector(`style[data-viewed-file-style="${id}"]`);
}

export const viewedAdapter = {
  clicks: {
    toggleViewed(event, checkbox) {
      const store = useCodeReview(pinia);
      const isViewed = checkbox.checked;
      const fileId = this.data.codeReviewId;

      store.setReviewed(fileId, isViewed);

      this.diffElement.toggleAttribute('data-viewed', isViewed);

      if (isViewed) {
        this.trigger(COLLAPSE_FILE_BY_USER);
      } else {
        this.trigger(EXPAND_FILE);
      }
    },
  },
  [MOUNTED]() {
    const checkbox = this.diffElement.querySelector('[data-viewed-checkbox]');
    if (!checkbox) return;
    if (!this.appData.codeReviewEnabled) return;

    const store = useCodeReview(pinia);
    const fileId = this.data.codeReviewId;
    const isViewed = Boolean(store.reviewedIds[fileId]);

    // Remove FOUC style - JS now controls collapse/expand via details element
    getViewedStyleElement(fileId)?.remove();

    checkbox.disabled = false;
    checkbox.checked = isViewed;
    this.diffElement.toggleAttribute('data-viewed', isViewed);

    if (isViewed) {
      this.trigger(COLLAPSE_FILE);
    }
  },
};
