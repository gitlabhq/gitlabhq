import { defineStore } from 'pinia';

export const useBatchComments = defineStore('batchComments', {
  state() {
    return {
      withBatchComments: true,
      isDraftsFetched: false,
      drafts: [],
      isPublishing: false,
      currentlyPublishingDrafts: [],
      shouldAnimateReviewButton: false,
      reviewBarRendered: false,
    };
  },
  actions: {
    addDraftToDiscussion() {},
    createNewDraft() {},
    clearDrafts() {},
  },
  getters: {
    hasDrafts() {},
  },
});
