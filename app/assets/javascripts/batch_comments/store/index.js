import { defineStore } from 'pinia';
import * as actions from './actions';
import mutations from './mutations';
import * as getters from './getters';

export const useBatchComments = defineStore('batchComments', {
  state() {
    return {
      isDraftsFetched: false,
      drafts: [],
      isPublishing: false,
      currentlyPublishingDrafts: [],
      shouldAnimateReviewButton: false,
      isMergeRequest: false,
      drawerOpened: false,
      // TODO: this gets populated from the sidebar_reviewers.vue, we should have a separate store for this
      isReviewer: false,
    };
  },
  actions: {
    ...mutations,
    ...actions,
  },
  getters,
});
