import { defineStore } from 'pinia';
import * as actions from './actions';
import mutations from './mutations';
import * as getters from './getters';

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
    ...mutations,
    ...actions,
  },
  getters,
});
