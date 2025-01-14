import * as types from '~/batch_comments/stores/modules/batch_comments/mutation_types';
import mutations from '~/batch_comments/stores/modules/batch_comments/mutations';
import createState from '~/batch_comments/stores/modules/batch_comments/state';

describe('Batch comments mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe(types.ADD_NEW_DRAFT, () => {
    const draft = { id: 1, note: 'test' };
    it('adds processed object into drafts array', () => {
      mutations[types.ADD_NEW_DRAFT](state, draft);

      expect(state.drafts).toEqual([
        {
          ...draft,
          isDraft: true,
        },
      ]);
    });

    it('sets `shouldAnimateReviewButton` to true if it is a first draft', () => {
      mutations[types.ADD_NEW_DRAFT](state, draft);

      expect(state.shouldAnimateReviewButton).toBe(true);
    });

    it('does not set `shouldAnimateReviewButton` to true if it is not a first draft', () => {
      state.drafts.push({ id: 1 }, { id: 2 });
      mutations[types.ADD_NEW_DRAFT](state, { id: 2, note: 'test2' });

      expect(state.shouldAnimateReviewButton).toBe(false);
    });
  });

  describe(types.DELETE_DRAFT, () => {
    it('removes draft from array by ID', () => {
      state.drafts.push({ id: 1 }, { id: 2 });

      mutations[types.DELETE_DRAFT](state, 1);

      expect(state.drafts).toEqual([{ id: 2 }]);
    });
  });

  describe(types.SET_BATCH_COMMENTS_DRAFTS, () => {
    it('adds to processed drafts in state', () => {
      const drafts = [{ id: 1 }, { id: 2 }];

      mutations[types.SET_BATCH_COMMENTS_DRAFTS](state, drafts);

      expect(state.drafts).toEqual([
        {
          id: 1,
          isDraft: true,
        },
        {
          id: 2,
          isDraft: true,
        },
      ]);
    });
  });

  describe(types.REQUEST_PUBLISH_REVIEW, () => {
    it('sets isPublishing to true', () => {
      mutations[types.REQUEST_PUBLISH_REVIEW](state);

      expect(state.isPublishing).toBe(true);
    });
  });

  describe(types.RECEIVE_PUBLISH_REVIEW_SUCCESS, () => {
    it('sets isPublishing to false', () => {
      state.isPublishing = true;

      mutations[types.RECEIVE_PUBLISH_REVIEW_SUCCESS](state);

      expect(state.isPublishing).toBe(false);
    });
  });

  describe(types.RECEIVE_PUBLISH_REVIEW_ERROR, () => {
    it('updates isPublishing to false', () => {
      state.isPublishing = true;

      mutations[types.RECEIVE_PUBLISH_REVIEW_ERROR](state);

      expect(state.isPublishing).toBe(false);
    });
  });

  describe(types.RECEIVE_DRAFT_UPDATE_SUCCESS, () => {
    it('updates draft in store', () => {
      state.drafts.push({ id: 1 });

      mutations[types.RECEIVE_DRAFT_UPDATE_SUCCESS](state, { id: 1, note: 'test' });

      expect(state.drafts).toEqual([
        {
          id: 1,
          note: 'test',
          isDraft: true,
        },
      ]);
    });
  });

  describe(types.CLEAR_DRAFTS, () => {
    it('clears drafts array', () => {
      state.drafts.push({ id: 1 });

      mutations[types.CLEAR_DRAFTS](state);

      expect(state.drafts).toEqual([]);
    });
  });

  describe(types.SET_DRAFT_EDITING, () => {
    it('sets draft editing mode', () => {
      state.drafts.push({ id: 1, isEditing: false });

      mutations[types.SET_DRAFT_EDITING](state, { draftId: 1, isEditing: true });

      expect(state.drafts[0].isEditing).toBe(true);
    });
  });
});
