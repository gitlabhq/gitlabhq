import * as types from './mutation_types';

const processDraft = (draft) => ({
  ...draft,
  isDraft: true,
});

export default {
  [types.ADD_NEW_DRAFT](state, draft) {
    state.drafts.push(processDraft(draft));
    if (state.drafts.length === 1) {
      state.shouldAnimateReviewButton = true;
    }
  },

  [types.DELETE_DRAFT](state, draftId) {
    state.drafts = state.drafts.filter((draft) => draft.id !== draftId);
  },

  [types.SET_BATCH_COMMENTS_DRAFTS](state, drafts) {
    state.drafts = drafts.map(processDraft);
  },

  [types.REQUEST_PUBLISH_DRAFT](state, draftId) {
    state.currentlyPublishingDrafts.push(draftId);
  },
  [types.RECEIVE_PUBLISH_DRAFT_SUCCESS](state, draftId) {
    state.currentlyPublishingDrafts = state.currentlyPublishingDrafts.filter(
      (publishingDraftId) => publishingDraftId !== draftId,
    );
    state.drafts = state.drafts.filter((d) => d.id !== draftId);
  },
  [types.RECEIVE_PUBLISH_DRAFT_ERROR](state, draftId) {
    state.currentlyPublishingDrafts = state.currentlyPublishingDrafts.filter(
      (publishingDraftId) => publishingDraftId !== draftId,
    );
  },

  [types.REQUEST_PUBLISH_REVIEW](state) {
    state.isPublishing = true;
  },
  [types.RECEIVE_PUBLISH_REVIEW_SUCCESS](state) {
    state.isPublishing = false;
  },
  [types.RECEIVE_PUBLISH_REVIEW_ERROR](state) {
    state.isPublishing = false;
  },
  [types.RECEIVE_DRAFT_UPDATE_SUCCESS](state, data) {
    const index = state.drafts.findIndex((draft) => draft.id === data.id);

    if (index >= 0) {
      state.drafts.splice(index, 1, processDraft(data));
    }
  },
  [types.TOGGLE_RESOLVE_DISCUSSION](state, draftId) {
    state.drafts = state.drafts.map((draft) => {
      if (draft.id === draftId) {
        return {
          ...draft,
          resolve_discussion: !draft.resolve_discussion,
        };
      }

      return draft;
    });
  },
  [types.CLEAR_DRAFTS](state) {
    state.drafts = [];
  },
  [types.SET_REVIEW_BAR_RENDERED](state) {
    state.reviewBarRendered = true;
  },
  [types.SET_DRAFT_EDITING](state, { draftId, isEditing }) {
    const draftIndex = state.drafts.findIndex((draft) => draft.id === draftId);
    const draft = state.drafts[draftIndex];
    state.drafts.splice(draftIndex, 1, { ...draft, isEditing });
  },
};
