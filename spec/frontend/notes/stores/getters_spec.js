import discussionWithTwoUnresolvedNotes from 'test_fixtures/merge_requests/resolved_diff_discussion.json';
import { DESC, ASC, NOTEABLE_TYPE_MAPPING } from '~/notes/constants';
import * as getters from '~/notes/stores/getters';
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
} from '../mock_data';

// Helper function to ensure that we're using the same schema across tests.
const createDiscussionNeighborParams = (discussionId, diffOrder, step) => ({
  discussionId,
  diffOrder,
  step,
});

const asDraftDiscussion = (x) => ({ ...x, individual_note: true });
const createRootState = () => {
  return {
    diffs: {
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
    },
  };
};

describe('Getters Notes Store', () => {
  let state;

  beforeEach(() => {
    state = {
      discussions: [individualNote],
      targetNoteHash: 'hash',
      lastFetchedAt: 'timestamp',
      isNotesFetched: false,
      notesData: notesDataMock,
      userData: userDataMock,
      noteableData: noteableDataMock,
      descriptionVersions: 'descriptionVersions',
      discussionSortOrder: DESC,
    };
  });

  describe('showJumpToNextDiscussion', () => {
    it('should return true if there are 2 or more unresolved discussions', () => {
      const localGetters = {
        unresolvedDiscussionsIdsByDate: ['123', '456'],
        allResolvableDiscussions: [],
      };

      expect(getters.showJumpToNextDiscussion(state, localGetters)()).toBe(true);
    });

    it('should return false if there are 1 or less unresolved discussions', () => {
      const localGetters = {
        unresolvedDiscussionsIdsByDate: ['123'],
        allResolvableDiscussions: [],
      };

      expect(getters.showJumpToNextDiscussion(state, localGetters)()).toBe(false);
    });
  });

  describe('discussions', () => {
    let batchComments = null;

    const getDiscussions = () => getters.discussions(state, {}, { batchComments });

    describe('merge request filters', () => {
      it('returns only bot comments', () => {
        const normalDiscussion = JSON.parse(JSON.stringify(discussionMock));
        const discussion = JSON.parse(JSON.stringify(discussionMock));
        discussion.notes[0].author.bot = true;

        const individualBotNote = JSON.parse(JSON.stringify(discussionMock));
        individualBotNote.notes[0].author.bot = true;
        individualBotNote.individual_note = true;

        state.noteableData = { targetType: 'merge_request' };
        state.discussions = [discussion, normalDiscussion, individualBotNote];
        state.mergeRequestFilters = ['bot_comments'];

        const discussions = getDiscussions();

        expect(discussions).toContain(discussion);
        expect(discussions).not.toContain(normalDiscussion);
        expect(discussions).toContain(individualBotNote);
      });
    });

    describe('without batchComments module', () => {
      it('should return all discussions in the store', () => {
        expect(getDiscussions()).toEqual([individualNote]);
      });

      it('should transform  discussion to individual notes in timeline view', () => {
        state.discussions = [discussionMock];
        state.isTimelineEnabled = true;

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
        batchComments = { drafts: [...draftComments, draftReply, draftDiffDiscussion] };
      });

      it.each`
        discussionSortOrder | expectation
        ${ASC}              | ${[individualNote, ...draftComments.map(asDraftDiscussion)]}
        ${DESC}             | ${[...draftComments.reverse().map(asDraftDiscussion), individualNote]}
      `(
        'only appends draft comments (discussionSortOrder=$discussionSortOrder)',
        ({ discussionSortOrder, expectation }) => {
          state.discussionSortOrder = discussionSortOrder;

          expect(getDiscussions()).toEqual(expectation);
        },
      );
    });
  });

  describe('hasDrafts', () => {
    it.each`
      rootGetters                             | expected
      ${{}}                                   | ${false}
      ${{ 'batchComments/hasDrafts': true }}  | ${true}
      ${{ 'batchComments/hasDrafts': false }} | ${false}
    `('with rootGetters=$rootGetters, returns $expected', ({ rootGetters, expected }) => {
      expect(getters.hasDrafts({}, {}, {}, rootGetters)).toBe(expected);
    });
  });

  describe('resolvedDiscussionsById', () => {
    it('ignores unresolved system notes', () => {
      const [discussion] = discussionWithTwoUnresolvedNotes;
      discussion.notes[0].resolved = true;
      discussion.notes[1].resolved = false;
      state.discussions.push(discussion);

      expect(getters.resolvedDiscussionsById(state)).toEqual({
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
      expect(getters.discussions(stateCollapsedNotes, {}, {}).length).toEqual(1);
    });
  });

  describe('targetNoteHash', () => {
    it('should return `targetNoteHash`', () => {
      expect(getters.targetNoteHash(state)).toEqual('hash');
    });
  });

  describe('getNotesData', () => {
    it('should return all data in `notesData`', () => {
      expect(getters.getNotesData(state)).toEqual(notesDataMock);
    });
  });

  describe('getNoteableData', () => {
    it('should return all data in `noteableData`', () => {
      expect(getters.getNoteableData(state)).toEqual(noteableDataMock);
    });
  });

  describe('getUserData', () => {
    it('should return all data in `userData`', () => {
      expect(getters.getUserData(state)).toEqual(userDataMock);
    });
  });

  describe('notesById', () => {
    it('should return the note for the given id', () => {
      expect(getters.notesById(state)).toEqual({ 1390: individualNote.notes[0] });
    });
  });

  describe('getCurrentUserLastNote', () => {
    it('should return the last note of the current user', () => {
      expect(getters.getCurrentUserLastNote(state)).toEqual(individualNote.notes[0]);
    });
  });

  describe('openState', () => {
    it('should return the issue state', () => {
      expect(getters.openState(state)).toEqual(noteableDataMock.state);
    });
  });

  describe('isNotesFetched', () => {
    it('should return the state for the fetching notes', () => {
      expect(getters.isNotesFetched(state)).toBe(false);
    });
  });

  describe('allResolvableDiscussions', () => {
    it('should return only resolvable discussions in same order', () => {
      state.discussions = [
        discussion3,
        unresolvableDiscussion,
        discussion1,
        unresolvableDiscussion,
        discussion2,
      ];

      expect(getters.allResolvableDiscussions(state)).toEqual([
        discussion3,
        discussion1,
        discussion2,
      ]);
    });

    it('should return empty array if there are no resolvable discussions', () => {
      state.discussions = [unresolvableDiscussion, unresolvableDiscussion];

      expect(getters.allResolvableDiscussions(state)).toEqual([]);
    });
  });

  describe('unresolvedDiscussionsIdsByDiff', () => {
    it('should return all discussions IDs in diff order', () => {
      const localGetters = {
        allResolvableDiscussions: [discussion3, discussion1, discussion2],
      };
      const rootState = createRootState();

      expect(getters.unresolvedDiscussionsIdsByDiff(state, localGetters, rootState)).toEqual([
        'abc1',
        'abc2',
        'abc3',
      ]);
    });

    // This is the same test as above, but it exercises the sorting algorithm
    // for a "strange" Diff File ordering. The intent is to ensure that even if lots
    // of shuffling has to occur, everything still works

    it('should return all discussions IDs in unusual diff order', () => {
      const localGetters = {
        allResolvableDiscussions: [discussion3, discussion1, discussion2],
      };
      const rootState = {
        diffs: {
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
        },
      };

      expect(getters.unresolvedDiscussionsIdsByDiff(state, localGetters, rootState)).toEqual([
        'abc3',
        'abc2',
        'abc1',
      ]);
    });

    it("should use the discussions array order if the files don't have explicit order values", () => {
      const localGetters = {
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
      const rootState = {
        diffs: { diffFiles: [auth2, auth1, auth3] }, // This order is not used!
      };

      delete auth1.order;
      delete auth2.order;
      delete auth3.order;

      expect(getters.unresolvedDiscussionsIdsByDiff(state, localGetters, rootState)).toEqual([
        'abc3',
        'abc1',
        'abc2',
      ]);
    });

    it('should return empty array if all discussions have been resolved', () => {
      const localGetters = {
        allResolvableDiscussions: [resolvedDiscussion1],
      };
      const rootState = createRootState();

      expect(getters.unresolvedDiscussionsIdsByDiff(state, localGetters, rootState)).toEqual([]);
    });
  });

  describe('unresolvedDiscussionsIdsByDate', () => {
    it('should return all discussions in date ascending order', () => {
      const localGetters = {
        allResolvableDiscussions: [discussion3, discussion1, discussion2],
      };

      expect(getters.unresolvedDiscussionsIdsByDate(state, localGetters)).toEqual([
        'abc2',
        'abc1',
        'abc3',
      ]);
    });

    it('should return empty array if all discussions have been resolved', () => {
      const localGetters = {
        allResolvableDiscussions: [resolvedDiscussion1],
      };

      expect(getters.unresolvedDiscussionsIdsByDate(state, localGetters)).toEqual([]);
    });
  });

  describe('unresolvedDiscussionsIdsOrdered', () => {
    const localGetters = {
      unresolvedDiscussionsIdsByDate: ['123', '456'],
      unresolvedDiscussionsIdsByDiff: ['abc', 'def'],
    };

    it('should return IDs ordered by diff when diffOrder param is true', () => {
      expect(getters.unresolvedDiscussionsIdsOrdered(state, localGetters)(true)).toEqual([
        'abc',
        'def',
      ]);
    });

    it('should return IDs ordered by date when diffOrder param is not true', () => {
      expect(getters.unresolvedDiscussionsIdsOrdered(state, localGetters)(false)).toEqual([
        '123',
        '456',
      ]);

      expect(getters.unresolvedDiscussionsIdsOrdered(state, localGetters)(undefined)).toEqual([
        '123',
        '456',
      ]);
    });
  });

  describe('isLastUnresolvedDiscussion', () => {
    const localGetters = {
      unresolvedDiscussionsIdsOrdered: () => ['123', '456', '789'],
    };

    it('should return true if the discussion id provided is the last', () => {
      expect(getters.isLastUnresolvedDiscussion(state, localGetters)('789')).toBe(true);
    });

    it('should return false if the discussion id provided is not the last', () => {
      expect(getters.isLastUnresolvedDiscussion(state, localGetters)('123')).toBe(false);
      expect(getters.isLastUnresolvedDiscussion(state, localGetters)('456')).toBe(false);
    });
  });

  describe('findUnresolvedDiscussionIdNeighbor', () => {
    let localGetters;
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

        expect(getters.findUnresolvedDiscussionIdNeighbor(state, localGetters)(params)).toBe(
          expected,
        );
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

          expect(getters.findUnresolvedDiscussionIdNeighbor(state, localGetters)(params)).toBe(
            expected,
          );
        });
      });

      it('with no match, returns only value', () => {
        const params = createDiscussionNeighborParams('bogus', true, 1);

        expect(getters.findUnresolvedDiscussionIdNeighbor(state, localGetters)(params)).toBe('123');
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

          expect(
            getters.findUnresolvedDiscussionIdNeighbor(state, localGetters)(params),
          ).toBeUndefined();
        });
      });
    });
  });

  describe('findUnresolvedDiscussionIdNeighbor aliases', () => {
    let neighbor;
    let findUnresolvedDiscussionIdNeighbor;
    let localGetters;

    beforeEach(() => {
      neighbor = {};
      findUnresolvedDiscussionIdNeighbor = jest.fn(() => neighbor);
      localGetters = { findUnresolvedDiscussionIdNeighbor };
    });

    describe('nextUnresolvedDiscussionId', () => {
      it('should return result of find neighbor', () => {
        const expectedParams = createDiscussionNeighborParams('123', true, 1);
        const result = getters.nextUnresolvedDiscussionId(state, localGetters)('123', true);

        expect(findUnresolvedDiscussionIdNeighbor).toHaveBeenCalledWith(expectedParams);
        expect(result).toBe(neighbor);
      });
    });

    describe('previosuUnresolvedDiscussionId', () => {
      it('should return result of find neighbor', () => {
        const expectedParams = createDiscussionNeighborParams('123', true, -1);
        const result = getters.previousUnresolvedDiscussionId(state, localGetters)('123', true);

        expect(findUnresolvedDiscussionIdNeighbor).toHaveBeenCalledWith(expectedParams);
        expect(result).toBe(neighbor);
      });
    });
  });

  describe('firstUnresolvedDiscussionId', () => {
    const localGetters = {
      unresolvedDiscussionsIdsByDate: ['123', '456'],
      unresolvedDiscussionsIdsByDiff: ['abc', 'def'],
    };

    it('should return the first discussion id by diff when diffOrder param is true', () => {
      expect(getters.firstUnresolvedDiscussionId(state, localGetters)(true)).toBe('abc');
    });

    it('should return the first discussion id by date when diffOrder param is not true', () => {
      expect(getters.firstUnresolvedDiscussionId(state, localGetters)(false)).toBe('123');
      expect(getters.firstUnresolvedDiscussionId(state, localGetters)(undefined)).toBe('123');
    });

    it('should be falsy if all discussions are resolved', () => {
      const localGettersFalsy = {
        unresolvedDiscussionsIdsByDiff: [],
        unresolvedDiscussionsIdsByDate: [],
      };

      expect(getters.firstUnresolvedDiscussionId(state, localGettersFalsy)(true)).toBeUndefined();
      expect(getters.firstUnresolvedDiscussionId(state, localGettersFalsy)(false)).toBeUndefined();
    });
  });

  describe('getDiscussion', () => {
    it('returns discussion by ID', () => {
      state.discussions.push({ id: '1' });

      expect(getters.getDiscussion(state)('1')).toEqual({ id: '1' });
    });
  });

  describe('descriptionVersions', () => {
    it('should return `descriptionVersions`', () => {
      expect(getters.descriptionVersions(state)).toEqual('descriptionVersions');
    });
  });

  describe('sortDirection', () => {
    it('should return `discussionSortOrder`', () => {
      expect(getters.sortDirection(state)).toBe(DESC);
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
        Object.assign(state, {
          userData,
          noteableData,
        });

        expect(getters.canUserAddIncidentTimelineEvents(state)).toBe(expected);
      },
    );
  });

  describe('allDiscussionsExpanded', () => {
    it('returns true when every discussion is expanded', () => {
      state = {
        discussions: [{ expanded: true }, { expanded: true }],
      };
      expect(getters.allDiscussionsExpanded(state)).toBe(true);
    });

    it('returns false when at least one discussion is collapsed', () => {
      state = {
        discussions: [{ expanded: true }, { expanded: false }],
      };
      expect(getters.allDiscussionsExpanded(state)).toBe(false);
    });
  });
});
