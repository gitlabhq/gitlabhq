import { createPinia, setActivePinia } from 'pinia';
import discussionWithTwoUnresolvedNotes from 'test_fixtures/merge_requests/resolved_diff_discussion.json';
import { DESC, ASC, NOTEABLE_TYPE_MAPPING } from '~/notes/constants';
import { createCustomGetters } from 'helpers/pinia_helpers';
import { useNotes } from '~/notes/store/legacy_notes';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useBatchComments } from '~/batch_comments/store';
import {
  notesDataMock,
  userDataMock,
  noteableDataMock,
  individualNote,
  collapseNotesMock,
  discussionMock,
  discussion1,
  discussion2,
  discussion3,
  resolvedDiscussion1,
  authoritativeDiscussionFile,
  unresolvableDiscussion,
  draftComments,
  draftReply,
  draftDiffDiscussion,
} from '../../mock_data';

// Helper function to ensure that we're using the same schema across tests.
const createDiscussionNeighborParams = (discussionId, diffOrder, step) => ({
  discussionId,
  diffOrder,
  step,
});

const asDraftDiscussion = (x) => ({ ...x, individual_note: true });
const createRootState = () => {
  return {
    diffFiles: [
      { ...authoritativeDiscussionFile },
      {
        ...authoritativeDiscussionFile,
        ...{ id: 'abc2', file_identifier_hash: 'discfile2', order: 1 },
      },
      {
        ...authoritativeDiscussionFile,
        ...{ id: 'abc3', file_identifier_hash: 'discfile3', order: 2 },
      },
    ],
  };
};

describe('Getters Notes Store', () => {
  let store;
  let localGetters;
  let batchComments;

  beforeEach(() => {
    localGetters = {};
    batchComments = {};
    setActivePinia(
      createPinia()
        .use(globalAccessorPlugin)
        .use(
          createCustomGetters(() => ({
            legacyNotes: localGetters,
            batchComments,
            legacyDiffs: {},
          })),
        ),
    );
    store = useNotes();
    useLegacyDiffs();
    store.$patch({
      discussions: [individualNote],
      targetNoteHash: 'hash',
      lastFetchedAt: 'timestamp',
      isNotesFetched: false,
      notesData: notesDataMock,
      userData: userDataMock,
      noteableData: noteableDataMock,
      descriptionVersions: 'descriptionVersions',
      discussionSortOrder: DESC,
    });
  });

  describe('showJumpToNextDiscussion', () => {
    it('should return true if there are 2 or more unresolved discussions', () => {
      localGetters = {
        unresolvedDiscussionsIdsByDate: ['123', '456'],
        allResolvableDiscussions: [],
      };

      expect(store.showJumpToNextDiscussion()).toBe(true);
    });

    it('should return false if there are 1 or less unresolved discussions', () => {
      localGetters = {
        unresolvedDiscussionsIdsByDate: ['123'],
        allResolvableDiscussions: [],
      };

      expect(store.showJumpToNextDiscussion()).toBe(false);
    });
  });

  describe('filteredDiscussions', () => {
    const getDiscussions = () => store.filteredDiscussions;

    describe('merge request filters', () => {
      it('returns only bot comments', () => {
        const normalDiscussion = JSON.parse(JSON.stringify(discussionMock));
        const discussion = JSON.parse(JSON.stringify(discussionMock));
        discussion.notes[0].author.bot = true;

        const individualBotNote = JSON.parse(JSON.stringify(discussionMock));
        individualBotNote.notes[0].author.bot = true;
        individualBotNote.individual_note = true;

        store.noteableData = { targetType: 'merge_request' };
        store.discussions = [discussion, normalDiscussion, individualBotNote];
        store.mergeRequestFilters = ['bot_comments'];

        const discussions = getDiscussions();

        expect(discussions).toContainEqual(discussion);
        expect(discussions).not.toContainEqual(normalDiscussion);
        expect(discussions).toContainEqual(individualBotNote);
      });
    });

    describe('without batchComments module', () => {
      it('should return all discussions in the store', () => {
        expect(getDiscussions()).toEqual([individualNote]);
      });

      it('should transform  discussion to individual notes in timeline view', () => {
        store.discussions = [discussionMock];
        store.isTimelineEnabled = true;

        const discussions = getDiscussions();

        expect(discussions.length).toEqual(discussionMock.notes.length);
        discussions.forEach((discussion) => {
          expect(discussion.individual_note).toBe(true);
          expect(discussion.id).toBe(discussion.notes[0].id);
          expect(discussion.created_at).toBe(discussion.notes[0].created_at);
        });
      });
    });

    describe('with batchComments', () => {
      beforeEach(() => {
        useBatchComments().drafts = [...draftComments, draftReply, draftDiffDiscussion];
      });

      it.each`
        discussionSortOrder | expectation
        ${ASC}              | ${[individualNote, ...draftComments.map(asDraftDiscussion)]}
        ${DESC}             | ${[...draftComments.reverse().map(asDraftDiscussion), individualNote]}
      `(
        'only appends draft comments (discussionSortOrder=$discussionSortOrder)',
        ({ discussionSortOrder, expectation }) => {
          store.discussionSortOrder = discussionSortOrder;

          expect(getDiscussions()).toEqual(expectation);
        },
      );
    });
  });

  describe('hasDrafts', () => {
    it.each`
      batchCommentsGetters    | expected
      ${{}}                   | ${false}
      ${{ hasDrafts: true }}  | ${true}
      ${{ hasDrafts: false }} | ${false}
    `('with rootGetters=$rootGetters, returns $expected', ({ batchCommentsGetters, expected }) => {
      batchComments = batchCommentsGetters;
      expect(store.hasDrafts).toBe(expected);
    });
  });

  describe('resolvedDiscussionsById', () => {
    it('ignores unresolved system notes', () => {
      const [discussion] = discussionWithTwoUnresolvedNotes;
      discussion.notes[0].resolved = true;
      discussion.notes[1].resolved = false;
      store.discussions.push(discussion);

      expect(store.resolvedDiscussionsById).toEqual({
        [discussion.id]: discussion,
      });
    });
  });

  describe('Collapsed notes', () => {
    const stateCollapsedNotes = {
      discussions: collapseNotesMock,
      targetNoteHash: 'hash',
      lastFetchedAt: 'timestamp',

      notesData: notesDataMock,
      userData: userDataMock,
      noteableData: noteableDataMock,
    };

    it('should return a single system note when a description was updated multiple times', () => {
      store.$patch(stateCollapsedNotes);
      expect(store.filteredDiscussions.length).toEqual(1);
    });
  });

  describe('targetNoteHash', () => {
    it('should return `targetNoteHash`', () => {
      expect(store.targetNoteHash).toEqual('hash');
    });
  });

  describe('getNotesData', () => {
    it('should return all data in `notesData`', () => {
      expect(store.getNotesData).toEqual(notesDataMock);
    });
  });

  describe('getNoteableData', () => {
    it('should return all data in `noteableData`', () => {
      expect(store.getNoteableData).toStrictEqual({
        // discussion_locked inherited from the original state
        discussion_locked: false,
        ...noteableDataMock,
      });
    });
  });

  describe('getUserData', () => {
    it('should return all data in `userData`', () => {
      expect(store.getUserData).toEqual(userDataMock);
    });
  });

  describe('notesById', () => {
    it('should return the note for the given id', () => {
      expect(store.notesById).toEqual({ 1390: individualNote.notes[0] });
    });
  });

  describe('getCurrentUserLastNote', () => {
    it('should return the last note of the current user', () => {
      expect(store.getCurrentUserLastNote).toEqual(individualNote.notes[0]);
    });
  });

  describe('openState', () => {
    it('should return the issue state', () => {
      expect(store.openState).toEqual(noteableDataMock.state);
    });
  });

  describe('isNotesFetched', () => {
    it('should return the state for the fetching notes', () => {
      expect(store.isNotesFetched).toBe(false);
    });
  });

  describe('allResolvableDiscussions', () => {
    it('should return only resolvable discussions in same order', () => {
      store.discussions = [
        discussion3,
        unresolvableDiscussion,
        discussion1,
        unresolvableDiscussion,
        discussion2,
      ];

      expect(store.allResolvableDiscussions).toEqual([discussion3, discussion1, discussion2]);
    });

    it('should return empty array if there are no resolvable discussions', () => {
      store.discussions = [unresolvableDiscussion, unresolvableDiscussion];

      expect(store.allResolvableDiscussions).toEqual([]);
    });
  });

  describe('unresolvedDiscussionsIdsByDiff', () => {
    it('should return all discussions IDs in diff order', () => {
      localGetters = {
        allResolvableDiscussions: [discussion3, discussion1, discussion2],
      };
      useLegacyDiffs().$patch(createRootState());

      expect(store.unresolvedDiscussionsIdsByDiff).toEqual(['abc1', 'abc2', 'abc3']);
    });

    // This is the same test as above, but it exercises the sorting algorithm
    // for a "strange" Diff File ordering. The intent is to ensure that even if lots
    // of shuffling has to occur, everything still works

    it('should return all discussions IDs in unusual diff order', () => {
      localGetters = {
        allResolvableDiscussions: [discussion3, discussion1, discussion2],
      };
      const rootState = {
        diffFiles: [
          // 2 is first, but should sort 2nd
          {
            ...authoritativeDiscussionFile,
            ...{ id: 'abc2', file_identifier_hash: 'discfile2', order: 1 },
          },
          // 1 is second, but should sort 3rd
          { ...authoritativeDiscussionFile, ...{ order: 2 } },
          // 3 is third, but should sort 1st
          {
            ...authoritativeDiscussionFile,
            ...{ id: 'abc3', file_identifier_hash: 'discfile3', order: 0 },
          },
        ],
      };
      useLegacyDiffs().$patch(rootState);

      expect(store.unresolvedDiscussionsIdsByDiff).toEqual(['abc3', 'abc2', 'abc1']);
    });

    it("should use the discussions array order if the files don't have explicit order values", () => {
      localGetters = {
        allResolvableDiscussions: [discussion3, discussion1, discussion2], // This order is used!
      };
      const auth1 = { ...authoritativeDiscussionFile };
      const auth2 = {
        ...authoritativeDiscussionFile,
        ...{ id: 'abc2', file_identifier_hash: 'discfile2' },
      };
      const auth3 = {
        ...authoritativeDiscussionFile,
        ...{ id: 'abc3', file_identifier_hash: 'discfile3' },
      };
      const rootState = { diffFiles: [auth2, auth1, auth3] }; // This order is not used!
      delete auth1.order;
      delete auth2.order;
      delete auth3.order;

      useLegacyDiffs().$patch(rootState);

      expect(store.unresolvedDiscussionsIdsByDiff).toEqual(['abc3', 'abc1', 'abc2']);
    });

    it('should return empty array if all discussions have been resolved', () => {
      localGetters = {
        allResolvableDiscussions: [resolvedDiscussion1],
      };
      useLegacyDiffs().$patch(createRootState());

      expect(store.unresolvedDiscussionsIdsByDiff).toEqual([]);
    });
  });

  describe('unresolvedDiscussionsIdsByDate', () => {
    it('should return all discussions in date ascending order', () => {
      localGetters = {
        allResolvableDiscussions: [discussion3, discussion1, discussion2],
      };

      expect(store.unresolvedDiscussionsIdsByDate).toEqual(['abc2', 'abc1', 'abc3']);
    });

    it('should return empty array if all discussions have been resolved', () => {
      localGetters = {
        allResolvableDiscussions: [resolvedDiscussion1],
      };

      expect(store.unresolvedDiscussionsIdsByDate).toEqual([]);
    });
  });

  describe('unresolvedDiscussionsIdsOrdered', () => {
    beforeEach(() => {
      localGetters = {
        unresolvedDiscussionsIdsByDate: ['123', '456'],
        unresolvedDiscussionsIdsByDiff: ['abc', 'def'],
      };
    });

    it('should return IDs ordered by diff when diffOrder param is true', () => {
      expect(store.unresolvedDiscussionsIdsOrdered(true)).toEqual(['abc', 'def']);
    });

    it('should return IDs ordered by date when diffOrder param is not true', () => {
      expect(store.unresolvedDiscussionsIdsOrdered(false)).toEqual(['123', '456']);

      expect(store.unresolvedDiscussionsIdsOrdered(undefined)).toEqual(['123', '456']);
    });
  });

  describe('isLastUnresolvedDiscussion', () => {
    beforeEach(() => {
      localGetters = {
        unresolvedDiscussionsIdsOrdered: () => ['123', '456', '789'],
      };
    });

    it('should return true if the discussion id provided is the last', () => {
      expect(store.isLastUnresolvedDiscussion('789')).toBe(true);
    });

    it('should return false if the discussion id provided is not the last', () => {
      expect(store.isLastUnresolvedDiscussion('123')).toBe(false);
      expect(store.isLastUnresolvedDiscussion('456')).toBe(false);
    });
  });

  describe('findUnresolvedDiscussionIdNeighbor', () => {
    beforeEach(() => {
      localGetters = {
        unresolvedDiscussionsIdsOrdered: () => ['123', '456', '789'],
      };
    });

    [
      { step: 1, id: '123', expected: '456' },
      { step: 1, id: '456', expected: '789' },
      { step: 1, id: '789', expected: '123' },
      { step: -1, id: '123', expected: '789' },
      { step: -1, id: '456', expected: '123' },
      { step: -1, id: '789', expected: '456' },
    ].forEach(({ step, id, expected }) => {
      it(`with step ${step} and id ${id}, returns next value`, () => {
        const params = createDiscussionNeighborParams(id, true, step);

        expect(store.findUnresolvedDiscussionIdNeighbor(params)).toBe(expected);
      });
    });

    describe('with 1 unresolved discussion', () => {
      beforeEach(() => {
        localGetters = {
          unresolvedDiscussionsIdsOrdered: () => ['123'],
        };
      });

      [
        { step: 1, id: '123', expected: '123' },
        { step: -1, id: '123', expected: '123' },
      ].forEach(({ step, id, expected }) => {
        it(`with step ${step} and match, returns only value`, () => {
          const params = createDiscussionNeighborParams(id, true, step);

          expect(store.findUnresolvedDiscussionIdNeighbor(params)).toBe(expected);
        });
      });

      it('with no match, returns only value', () => {
        const params = createDiscussionNeighborParams('bogus', true, 1);

        expect(store.findUnresolvedDiscussionIdNeighbor(params)).toBe('123');
      });
    });

    describe('with 0 unresolved discussions', () => {
      beforeEach(() => {
        localGetters = {
          unresolvedDiscussionsIdsOrdered: () => [],
        };
      });

      [{ step: 1 }, { step: -1 }].forEach(({ step }) => {
        it(`with step ${step}, returns undefined`, () => {
          const params = createDiscussionNeighborParams('bogus', true, step);

          expect(store.findUnresolvedDiscussionIdNeighbor(params)).toBeUndefined();
        });
      });
    });
  });

  describe('findUnresolvedDiscussionIdNeighbor aliases', () => {
    let neighbor;
    let findUnresolvedDiscussionIdNeighbor;

    beforeEach(() => {
      neighbor = {};
      findUnresolvedDiscussionIdNeighbor = jest.fn(() => neighbor);
      localGetters = { findUnresolvedDiscussionIdNeighbor };
    });

    describe('nextUnresolvedDiscussionId', () => {
      it('should return result of find neighbor', () => {
        const expectedParams = createDiscussionNeighborParams('123', true, 1);
        const result = store.nextUnresolvedDiscussionId('123', true);

        expect(findUnresolvedDiscussionIdNeighbor).toHaveBeenCalledWith(expectedParams);
        expect(result).toBe(neighbor);
      });
    });

    describe('previosuUnresolvedDiscussionId', () => {
      it('should return result of find neighbor', () => {
        const expectedParams = createDiscussionNeighborParams('123', true, -1);
        const result = store.previousUnresolvedDiscussionId('123', true);

        expect(findUnresolvedDiscussionIdNeighbor).toHaveBeenCalledWith(expectedParams);
        expect(result).toBe(neighbor);
      });
    });
  });

  describe('firstUnresolvedDiscussionId', () => {
    beforeEach(() => {
      localGetters = {
        unresolvedDiscussionsIdsByDate: ['123', '456'],
        unresolvedDiscussionsIdsByDiff: ['abc', 'def'],
      };
    });

    it('should return the first discussion id by diff when diffOrder param is true', () => {
      expect(store.firstUnresolvedDiscussionId(true)).toBe('abc');
    });

    it('should return the first discussion id by date when diffOrder param is not true', () => {
      expect(store.firstUnresolvedDiscussionId(false)).toBe('123');
      expect(store.firstUnresolvedDiscussionId(undefined)).toBe('123');
    });

    it('should be falsy if all discussions are resolved', () => {
      localGetters = {
        unresolvedDiscussionsIdsByDiff: [],
        unresolvedDiscussionsIdsByDate: [],
      };

      expect(store.firstUnresolvedDiscussionId(true)).toBeUndefined();
      expect(store.firstUnresolvedDiscussionId(false)).toBeUndefined();
    });
  });

  describe('getDiscussion', () => {
    it('returns discussion by ID', () => {
      store.discussions.push({ id: '1' });

      expect(store.getDiscussion('1')).toEqual({ id: '1' });
    });
  });

  describe('descriptionVersions', () => {
    it('should return `descriptionVersions`', () => {
      expect(store.descriptionVersions).toEqual('descriptionVersions');
    });
  });

  describe('sortDirection', () => {
    it('should return `discussionSortOrder`', () => {
      expect(store.sortDirection).toBe(DESC);
    });
  });

  describe('canUserAddIncidentTimelineEvents', () => {
    it.each`
      userData                              | noteableData                                | expected
      ${{ can_add_timeline_events: true }}  | ${{ type: NOTEABLE_TYPE_MAPPING.Incident }} | ${true}
      ${{ can_add_timeline_events: true }}  | ${{ type: NOTEABLE_TYPE_MAPPING.Issue }}    | ${false}
      ${null}                               | ${{ type: NOTEABLE_TYPE_MAPPING.Incident }} | ${false}
      ${{ can_add_timeline_events: false }} | ${{ type: NOTEABLE_TYPE_MAPPING.Incident }} | ${false}
    `(
      'with userData=$userData and noteableData=$noteableData, expected=$expected',
      ({ userData, noteableData, expected }) => {
        store.$patch({
          userData,
          noteableData,
        });

        expect(store.canUserAddIncidentTimelineEvents).toBe(expected);
      },
    );
  });

  describe('allDiscussionsExpanded', () => {
    it('returns true when every discussion is expanded', () => {
      store.$patch({
        discussions: [{ expanded: true }, { expanded: true }],
      });
      expect(store.allDiscussionsExpanded).toBe(true);
    });

    it('returns false when at least one discussion is collapsed', () => {
      store.$patch({
        discussions: [{ expanded: true }, { expanded: false }],
      });
      expect(store.allDiscussionsExpanded).toBe(false);
    });
  });
});
