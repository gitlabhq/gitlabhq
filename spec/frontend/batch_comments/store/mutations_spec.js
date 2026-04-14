import { createTestingPinia } from '@pinia/testing';
import * as types from '~/batch_comments/stores/modules/batch_comments/mutation_types';
import { useBatchComments } from '~/batch_comments/store';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useNotes } from '~/notes/store/legacy_notes';

describe('Batch comments mutations', () => {
  let store;

  beforeEach(() => {
    createTestingPinia({ stubActions: false, plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes();
    store = useBatchComments();
  });

  describe(types.ADD_NEW_DRAFT, () => {
    const draft = { id: 1, note: 'test' };
    it('adds processed object into drafts array', () => {
      store[types.ADD_NEW_DRAFT](draft);

      expect(store.drafts).toEqual([
        {
          ...draft,
          isDraft: true,
          isEditing: false,
          editedNote: null,
        },
      ]);
    });

    it('adds reactive properties with correct defaults', () => {
      store[types.ADD_NEW_DRAFT](draft);

      const added = store.drafts[0];
      expect(added.isEditing).toBe(false);
      expect(added.editedNote).toBeNull();
    });

    it('does not overwrite existing reactive properties from input', () => {
      store[types.ADD_NEW_DRAFT]({ id: 2, note: 'test', isEditing: true });

      const added = store.drafts[0];
      expect(added.isEditing).toBe(true);
    });

    it('sets `shouldAnimateReviewButton` to true if it is a first draft', () => {
      store[types.ADD_NEW_DRAFT](draft);

      expect(store.shouldAnimateReviewButton).toBe(true);
    });

    it('does not set `shouldAnimateReviewButton` to true if it is not a first draft', () => {
      store.drafts.push({ id: 1 }, { id: 2 });
      store[types.ADD_NEW_DRAFT]({ id: 2, note: 'test2' });

      expect(store.shouldAnimateReviewButton).toBe(false);
    });
  });

  describe(types.DELETE_DRAFT, () => {
    it('removes draft from array by ID', () => {
      store.drafts.push({ id: 1 }, { id: 2 });

      store[types.DELETE_DRAFT](1);

      expect(store.drafts).toEqual([{ id: 2 }]);
    });
  });

  describe(types.SET_BATCH_COMMENTS_DRAFTS, () => {
    it('adds to processed drafts in state', () => {
      const drafts = [{ id: 1 }, { id: 2 }];

      store[types.SET_BATCH_COMMENTS_DRAFTS](drafts);

      expect(store.drafts).toEqual([
        { id: 1, isDraft: true, isEditing: false, editedNote: null },
        { id: 2, isDraft: true, isEditing: false, editedNote: null },
      ]);
    });
  });

  describe(types.REQUEST_PUBLISH_REVIEW, () => {
    it('sets isPublishing to true', () => {
      store[types.REQUEST_PUBLISH_REVIEW]();

      expect(store.isPublishing).toBe(true);
    });
  });

  describe(types.RECEIVE_PUBLISH_REVIEW_SUCCESS, () => {
    it('sets isPublishing to false', () => {
      store.isPublishing = true;

      store[types.RECEIVE_PUBLISH_REVIEW_SUCCESS]();

      expect(store.isPublishing).toBe(false);
    });
  });

  describe(types.RECEIVE_PUBLISH_REVIEW_ERROR, () => {
    it('updates isPublishing to false', () => {
      store.isPublishing = true;

      store[types.RECEIVE_PUBLISH_REVIEW_ERROR]();

      expect(store.isPublishing).toBe(false);
    });
  });

  describe(types.RECEIVE_DRAFT_UPDATE_SUCCESS, () => {
    it('updates draft in store with reactive properties', () => {
      store.drafts.push({ id: 1 });

      store[types.RECEIVE_DRAFT_UPDATE_SUCCESS]({ id: 1, note: 'test' });

      expect(store.drafts).toEqual([
        { id: 1, note: 'test', isDraft: true, isEditing: false, editedNote: null },
      ]);
    });
  });

  describe(types.CLEAR_DRAFTS, () => {
    it('clears drafts array', () => {
      store.drafts.push({ id: 1 });

      store[types.CLEAR_DRAFTS]();

      expect(store.drafts).toEqual([]);
    });
  });

  describe(types.SET_DRAFT_EDITING, () => {
    it('sets draft editing mode', () => {
      store.drafts.push({ id: 1, isEditing: false });

      store[types.SET_DRAFT_EDITING]({ draftId: 1, isEditing: true });

      expect(store.drafts[0].isEditing).toBe(true);
    });
  });
});
