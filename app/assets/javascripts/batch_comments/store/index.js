import { defineStore } from 'pinia';
import mrNotes from '~/mr_notes/stores';
import * as actions from './actions';
import mutations from './mutations';
import * as getters from './getters';

export const useBatchComments = defineStore('batchComments', {
  syncWith: {
    store: mrNotes,
    name: 'batchComments',
    namespaced: true,
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
