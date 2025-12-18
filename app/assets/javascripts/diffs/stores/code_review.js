import { defineStore } from 'pinia';

export const useCodeReview = defineStore('codeReview', {
  state() {
    return {
      mrPath: '',
      reviewedIds: {},
    };
  },
  actions: {
    setMrPath(path) {
      this.mrPath = path;
    },
    restoreFromAutosave() {
      const reviews = localStorage.getItem(this.autosaveKey);
      if (!reviews) return;
      const ids = JSON.parse(reviews);
      ids.forEach((id) => {
        this.reviewedIds[id] = true;
      });
      this.reviewedIds = { ...this.reviewedIds };
    },
    restoreFromLegacyMrReviews() {
      const reviewsForMr = localStorage.getItem(`${this.mrPath}-file-reviews`);
      if (!reviewsForMr) return;
      const reviews = JSON.parse(reviewsForMr);
      Object.values(reviews).forEach((values) => {
        values.forEach((value) => {
          // eslint-disable-next-line @gitlab/require-i18n-strings
          if (!value.startsWith('hash:')) this.reviewedIds[value] = true;
        });
      });
      this.reviewedIds = { ...this.reviewedIds };
      localStorage.removeItem(`${this.mrPath}-file-reviews`);
      this.autosave();
    },
    setReviewed(id, reviewed) {
      this.reviewedIds = { ...this.reviewedIds, [id]: reviewed };
      this.autosave();
    },
    removeId(id) {
      delete this.reviewedIds[id];
    },
    autosave() {
      const ids = this.markedAsViewedIds;
      if (ids.length) {
        localStorage.setItem(this.autosaveKey, JSON.stringify(ids));
      } else {
        localStorage.removeItem(this.autosaveKey);
      }
    },
  },
  getters: {
    markedAsViewedIds() {
      return Object.keys(this.reviewedIds).reduce((acc, key) => {
        if (this.reviewedIds[key]) acc.push(key);
        return acc;
      }, []);
    },
    autosaveKey() {
      return `code-review-${this.mrPath}`;
    },
  },
});
