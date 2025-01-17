import * as types from '../stores/modules/batch_comments/mutation_types';

const processDraft = (draft) => ({
  ...draft,
  isDraft: true,
});

export default {
  [types.ADD_NEW_DRAFT](draft) {
    this.drafts.push(processDraft(draft));
    if (this.drafts.length === 1) {
      this.shouldAnimateReviewButton = true;
    }
  },

  [types.DELETE_DRAFT](draftId) {
    this.drafts = this.drafts.filter((draft) => draft.id !== draftId);
  },

  [types.SET_BATCH_COMMENTS_DRAFTS](drafts) {
    this.drafts = drafts.map(processDraft);
  },

  [types.REQUEST_PUBLISH_DRAFT](draftId) {
    this.currentlyPublishingDrafts.push(draftId);
  },
  [types.RECEIVE_PUBLISH_DRAFT_SUCCESS](draftId) {
    this.currentlyPublishingDrafts = this.currentlyPublishingDrafts.filter(
      (publishingDraftId) => publishingDraftId !== draftId,
    );
    this.drafts = this.drafts.filter((d) => d.id !== draftId);
  },
  [types.RECEIVE_PUBLISH_DRAFT_ERROR](draftId) {
    this.currentlyPublishingDrafts = this.currentlyPublishingDrafts.filter(
      (publishingDraftId) => publishingDraftId !== draftId,
    );
  },

  [types.REQUEST_PUBLISH_REVIEW]() {
    this.isPublishing = true;
  },
  [types.RECEIVE_PUBLISH_REVIEW_SUCCESS]() {
    this.isPublishing = false;
  },
  [types.RECEIVE_PUBLISH_REVIEW_ERROR]() {
    this.isPublishing = false;
  },
  [types.RECEIVE_DRAFT_UPDATE_SUCCESS](data) {
    const index = this.drafts.findIndex((draft) => draft.id === data.id);

    if (index >= 0) {
      this.drafts.splice(index, 1, processDraft(data));
    }
  },
  [types.TOGGLE_RESOLVE_DISCUSSION](draftId) {
    this.drafts = this.drafts.map((draft) => {
      if (draft.id === draftId) {
        return {
          ...draft,
          resolve_discussion: !draft.resolve_discussion,
        };
      }

      return draft;
    });
  },
  [types.CLEAR_DRAFTS]() {
    this.drafts = [];
  },
  [types.SET_REVIEW_BAR_RENDERED]() {
    this.reviewBarRendered = true;
  },
  [types.SET_DRAFT_EDITING]({ draftId, isEditing }) {
    const draftIndex = this.drafts.findIndex((draft) => draft.id === draftId);
    const draft = this.drafts[draftIndex];
    this.drafts.splice(draftIndex, 1, { ...draft, isEditing });
  },
};
