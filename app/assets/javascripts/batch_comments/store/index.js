import { defineStore } from 'pinia';
import mrNotes from '~/mr_notes/stores';
import * as actions from './actions';
import mutations from './mutations';
import * as getters from './getters';

export const useBatchComments = defineStore('batchComments', {
  syncWith: {
    store: mrNotes,
    namespace: 'batchComments',
  },
  state() {
    return {
      isDraftsFetched: false,
      drafts: [],
      isPublishing: false,
      currentlyPublishingDrafts: [],
      shouldAnimateReviewButton: false,
      reviewBarRendered: false,
      isMergeRequest: false,
    };
  },
  actions: {
    ...mutations,
    ...actions,
  },
  getters,
});
