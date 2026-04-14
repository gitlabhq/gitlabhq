import { createTestingPinia } from '@pinia/testing';
import { useMergeRequestDraftNotes } from '~/merge_request/stores/merge_request_draft_notes';
import { useBatchComments } from '~/batch_comments/store';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useNotes } from '~/notes/store/legacy_notes';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';

describe('mergeRequestDraftNotes store', () => {
  let store;

  const makeDraft = (id, overrides = {}) => ({
    id,
    position: {
      position_type: 'text',
      old_path: 'a.js',
      new_path: 'a.js',
      old_line: 1,
      new_line: 1,
    },
    ...overrides,
  });

  const makeFileDraft = (id, overrides = {}) =>
    makeDraft(id, {
      position: { position_type: 'file', old_path: 'a.js', new_path: 'a.js' },
      ...overrides,
    });

  const makeImageDraft = (id, overrides = {}) => ({
    id,
    position: { position_type: 'image', old_path: 'a.png', new_path: 'a.png' },
    ...overrides,
  });

  beforeEach(() => {
    createTestingPinia({ stubActions: false, plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes();
    store = useMergeRequestDraftNotes();
  });

  describe('computed getters', () => {
    it('exposes drafts from batchComments', () => {
      const draft = makeDraft(1);
      useBatchComments().$patch({ drafts: [draft] });

      expect(store.drafts).toEqual([draft]);
    });

    it.each([
      ['hasDrafts', [makeDraft(1)], true],
      ['hasDrafts', [], false],
      ['draftsCount', [makeDraft(1), makeDraft(2)], 2],
    ])('%s with %o drafts', (getter, drafts, expected) => {
      useBatchComments().$patch({ drafts });

      expect(store[getter]).toBe(expected);
    });

    it('isPublishing reflects batchComments.isPublishing', () => {
      useBatchComments().$patch({ isPublishing: true });

      expect(store.isPublishing).toBe(true);
    });
  });

  describe.each([
    {
      method: 'findDraftsAsDiscussionsForFile',
      paths: { oldPath: 'a.js', newPath: 'a.js' },
      makeMatchingDraft: () => makeDraft(1),
      makeNonMatchingDrafts: () => [
        makeDraft(1, { position: { position_type: 'text', old_path: 'b.js', new_path: 'b.js' } }),
        { id: 1 },
      ],
    },
    {
      method: 'findDraftsAsFileDiscussionsForFile',
      paths: { oldPath: 'a.js', newPath: 'a.js' },
      makeMatchingDraft: () => makeFileDraft(1),
      makeNonMatchingDrafts: () => [
        makeDraft(1),
        makeFileDraft(1, {
          position: { position_type: 'file', old_path: 'b.js', new_path: 'b.js' },
        }),
      ],
    },
    {
      method: 'findDraftsAsLineDiscussionsForFile',
      paths: { oldPath: 'a.js', newPath: 'a.js' },
      makeMatchingDraft: () => makeDraft(1),
      makeNonMatchingDrafts: () => [
        makeFileDraft(1),
        makeImageDraft(1, {
          position: { position_type: 'image', old_path: 'a.js', new_path: 'a.js' },
        }),
        makeDraft(1, { position: { position_type: 'text', old_path: 'b.js', new_path: 'b.js' } }),
      ],
    },
    {
      method: 'findDraftsAsImageDiscussionsForFile',
      paths: { oldPath: 'a.png', newPath: 'a.png' },
      makeMatchingDraft: () => makeImageDraft(1),
      makeNonMatchingDrafts: () => [
        makeImageDraft(1, {
          position: { position_type: 'image', old_path: 'b.png', new_path: 'b.png' },
        }),
        makeDraft(1, {
          position: {
            position_type: 'text',
            old_path: 'a.png',
            new_path: 'a.png',
            old_line: 1,
            new_line: 1,
          },
        }),
        makeFileDraft(1, {
          position: { position_type: 'file', old_path: 'a.png', new_path: 'a.png' },
        }),
      ],
    },
  ])('$method', ({ method, paths, makeMatchingDraft, makeNonMatchingDrafts }) => {
    it('returns matching drafts as pseudo-discussions', () => {
      useBatchComments().$patch({ drafts: [makeMatchingDraft()] });

      const result = store[method](paths);

      expect(result).toHaveLength(1);
      expect(result[0]).toMatchObject({ id: 'draft_1', isDraft: true, diff_discussion: true });
    });

    it('returns multiple matching drafts', () => {
      const d1 = makeMatchingDraft();
      const d2 = makeMatchingDraft();
      d2.id = 2;
      useBatchComments().$patch({ drafts: [d1, d2] });

      expect(store[method](paths)).toHaveLength(2);
    });

    it.each(makeNonMatchingDrafts().map((d) => [d]))('excludes non-matching draft %o', (draft) => {
      useBatchComments().$patch({ drafts: [draft] });

      expect(store[method](paths)).toHaveLength(0);
    });

    it('excludes reply drafts (those with discussion_id)', () => {
      const draft = makeMatchingDraft();
      draft.discussion_id = 'disc-1';
      useBatchComments().$patch({ drafts: [draft] });

      expect(store[method](paths)).toHaveLength(0);
    });
  });

  describe('findDraftsAsDiscussionsForFile', () => {
    it('maps draft to pseudo-discussion shape', () => {
      useBatchComments().$patch({ drafts: [makeDraft(1)] });

      const [result] = store.findDraftsAsDiscussionsForFile({ oldPath: 'a.js', newPath: 'a.js' });

      expect(result).toMatchObject({
        id: 'draft_1',
        isDraft: true,
        diff_discussion: true,
        resolvable: false,
        resolved: false,
        repliesExpanded: true,
        notes: [expect.objectContaining({ id: 1 })],
      });
    });
  });

  describe('findDraftsForPosition', () => {
    const pos = { oldPath: 'a.js', newPath: 'a.js', oldLine: 1, newLine: 1 };

    it('returns drafts matching the exact line position', () => {
      useBatchComments().$patch({ drafts: [makeDraft(1)] });

      const result = store.findDraftsForPosition(pos);

      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('draft_1');
    });

    it.each([
      [
        'different lines',
        makeDraft(1, {
          position: {
            position_type: 'text',
            old_path: 'a.js',
            new_path: 'a.js',
            old_line: 5,
            new_line: 5,
          },
        }),
      ],
      [
        'different paths',
        makeDraft(1, {
          position: {
            position_type: 'text',
            old_path: 'b.js',
            new_path: 'b.js',
            old_line: 1,
            new_line: 1,
          },
        }),
      ],
      ['reply draft', makeDraft(1, { discussion_id: 'disc-1' })],
    ])('excludes drafts with %s', (_, draft) => {
      useBatchComments().$patch({ drafts: [draft] });

      expect(store.findDraftsForPosition(pos)).toHaveLength(0);
    });
  });

  describe('findDraftsForDiscussion', () => {
    it('returns the draft matching the given discussion id', () => {
      useBatchComments().$patch({ drafts: [makeDraft(1, { discussion_id: 'disc-1' })] });

      expect(store.findDraftsForDiscussion('disc-1')).toMatchObject([{ id: 1 }]);
    });

    it('returns undefined when no draft matches', () => {
      expect(store.findDraftsForDiscussion('disc-1')).toHaveLength(0);
    });
  });

  describe('fetchDrafts', () => {
    it.each([
      [true, { current_user_id: 1 }, true],
      [false, {}, false],
    ])('calls fetchDrafts: %s when gon.current_user_id is set: %s', async (_, gon, shouldCall) => {
      window.gon = gon;
      const fetchDrafts = jest.fn().mockResolvedValue();
      useBatchComments().fetchDrafts = fetchDrafts;

      await store.fetchDrafts();

      if (shouldCall) {
        expect(fetchDrafts).toHaveBeenCalled();
      } else {
        expect(fetchDrafts).not.toHaveBeenCalled();
      }
    });
  });

  it.each([
    'createNewDraft',
    'addDraftToDiscussion',
    'updateDraft',
    'deleteDraft',
    'publishReview',
    'discardDrafts',
  ])('exposes %s from batchComments', (action) => {
    expect(store[action]).toEqual(expect.any(Function));
  });
});
