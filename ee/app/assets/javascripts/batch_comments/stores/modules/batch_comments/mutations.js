import * as types from './mutation_types';

const processDraft = draft => ({
  ...draft,
  isDraft: true,
});

export default {
  [types.ENABLE_BATCH_COMMENTS](state) {
    state.withBatchComments = true;
  },

  [types.ADD_NEW_DRAFT](state, draft) {
    state.drafts.push(processDraft(draft));
  },

  [types.DELETE_DRAFT](state, draftId) {
    state.drafts = state.drafts.filter(draft => draft.id !== draftId);
  },

  [types.SET_BATCH_COMMENTS_DRAFTS](state, drafts) {
    state.drafts = drafts.map(processDraft);
  },

  [types.REQUEST_PUBLISH_DRAFT](state, draftId) {
    state.currentlyPublishingDrafts.push(draftId);
  },
  [types.RECEIVE_PUBLISH_DRAFT_SUCCESS](state, draftId) {
    state.currentlyPublishingDrafts = state.currentlyPublishingDrafts.filter(
      publishingDraftId => publishingDraftId !== draftId,
    );
    state.drafts = state.drafts.filter(d => d.id !== draftId);
  },
  [types.RECEIVE_PUBLISH_DRAFT_ERROR](state, draftId) {
    state.currentlyPublishingDrafts = state.currentlyPublishingDrafts.filter(
      publishingDraftId => publishingDraftId !== draftId,
    );
  },

  [types.REQUEST_PUBLISH_REVIEW](state) {
    state.isPublishing = true;
  },
  [types.RECEIVE_PUBLISH_REVIEW_SUCCESS](state) {
    state.isPublishing = false;
    state.drafts = [];
  },
  [types.RECEIVE_PUBLISH_REVIEW_ERROR](state) {
    state.isPublishing = false;
  },
  [types.REQUEST_DISCARD_REVIEW](state) {
    state.isDiscarding = true;
  },
  [types.RECEIVE_DISCARD_REVIEW_SUCCESS](state) {
    state.isDiscarding = false;
    state.drafts = [];
  },
  [types.RECEIVE_DISCARD_REVIEW_ERROR](state) {
    state.isDiscarding = false;
  },
  [types.RECEIVE_DRAFT_UPDATE_SUCCESS](state, data) {
    const index = state.drafts.findIndex(draft => draft.id === data.id);

    if (index >= 0) {
      state.drafts.splice(index, 1, processDraft(data));
    }
  },
};
