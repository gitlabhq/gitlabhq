import * as types from '~/batch_comments/stores/modules/batch_comments/mutation_types';
import mutations from '~/batch_comments/stores/modules/batch_comments/mutations';
import createState from '~/batch_comments/stores/modules/batch_comments/state';

describe('Batch comments mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe(types.ADD_NEW_DRAFT, () => {
    it('adds processed object into drafts array', () => {
      const draft = { id: 1, note: 'test' };

      mutations[types.ADD_NEW_DRAFT](state, draft);

      expect(state.drafts).toEqual([
        {
          ...draft,
          isDraft: true,
        },
      ]);
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
    it('resets drafts', () => {
      state.drafts.push('test');

      mutations[types.RECEIVE_PUBLISH_REVIEW_SUCCESS](state);

      expect(state.drafts).toEqual([]);
    });

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
});
