import {
  getMovePositionIds,
  boardColumnQueryVariables,
  boardColumnCountVariables,
} from '~/work_items/board/utils';

describe('work item board utils', () => {
  describe('boardColumnQueryVariables', () => {
    const baseQueryVariables = { state: 'opened', sort: 'CREATED_DESC' };

    it('merges the group filter over the base variables and adds paging', () => {
      expect(
        boardColumnQueryVariables({
          rootPageFullPath: 'full/path',
          baseQueryVariables,
          groupFilter: { status: { name: 'To do' } },
        }),
      ).toEqual({
        fullPath: 'full/path',
        state: 'opened',
        sort: 'CREATED_DESC',
        firstPageSize: 20,
        status: { name: 'To do' },
      });
    });

    it('lets the group filter override colliding base variables', () => {
      expect(
        boardColumnQueryVariables({
          rootPageFullPath: 'full/path',
          baseQueryVariables: { ...baseQueryVariables, status: { name: 'overridden' } },
          groupFilter: { status: { name: 'To do' } },
        }),
      ).toMatchObject({ status: { name: 'To do' } });
    });

    describe('when the base variables carry List view pagination state', () => {
      it('drops the list cursors and lastPageSize', () => {
        expect(
          boardColumnQueryVariables({
            rootPageFullPath: 'full/path',
            baseQueryVariables: {
              ...baseQueryVariables,
              afterCursor: 'eyJjcmVhdGVkX2F0IjoiMjAyNi0wOC0zMSJ9',
              beforeCursor: 'eyJjcmVhdGVkX2F0IjoiMjAyNi0wOC0wMSJ9',
              lastPageSize: 20,
            },
            groupFilter: { status: { name: 'To do' } },
          }),
        ).toEqual({
          fullPath: 'full/path',
          state: 'opened',
          sort: 'CREATED_DESC',
          firstPageSize: 20,
          status: { name: 'To do' },
        });
      });
    });
  });

  describe('boardColumnCountVariables', () => {
    it('drops firstPageSize along with the List view pagination state', () => {
      expect(
        boardColumnCountVariables({
          rootPageFullPath: 'full/path',
          baseQueryVariables: {
            state: 'opened',
            sort: 'CREATED_DESC',
            afterCursor: 'eyJjcmVhdGVkX2F0IjoiMjAyNi0wOC0zMSJ9',
            lastPageSize: 20,
          },
          groupFilter: { status: { name: 'To do' } },
        }),
      ).toEqual({
        fullPath: 'full/path',
        state: 'opened',
        sort: 'CREATED_DESC',
        status: { name: 'To do' },
      });
    });
  });

  describe('getMovePositionIds', () => {
    const nodes = [
      { id: 'gid://gitlab/WorkItem/1' },
      { id: 'gid://gitlab/WorkItem/2' },
      { id: 'gid://gitlab/WorkItem/3' },
    ];

    describe('within the same column', () => {
      it('returns the card at the drop index as moveBeforeId when moving down', () => {
        expect(getMovePositionIds({ nodes, sameColumn: true, oldIndex: 0, newIndex: 2 })).toEqual({
          moveBeforeId: 'gid://gitlab/WorkItem/3',
        });
      });

      it('returns the card at the drop index as moveAfterId when moving up', () => {
        expect(getMovePositionIds({ nodes, sameColumn: true, oldIndex: 2, newIndex: 0 })).toEqual({
          moveAfterId: 'gid://gitlab/WorkItem/1',
        });
      });

      it('returns no ids when dropped in place', () => {
        expect(getMovePositionIds({ nodes, sameColumn: true, oldIndex: 1, newIndex: 1 })).toEqual(
          {},
        );
      });
    });

    describe('across columns', () => {
      it('returns the surrounding cards when dropped between two cards', () => {
        expect(getMovePositionIds({ nodes, sameColumn: false, newIndex: 1 })).toEqual({
          moveBeforeId: 'gid://gitlab/WorkItem/1',
          moveAfterId: 'gid://gitlab/WorkItem/2',
        });
      });

      it('returns only moveAfterId when dropped at the start', () => {
        expect(getMovePositionIds({ nodes, sameColumn: false, newIndex: 0 })).toEqual({
          moveBeforeId: undefined,
          moveAfterId: 'gid://gitlab/WorkItem/1',
        });
      });

      it('returns only moveBeforeId when dropped at the end', () => {
        expect(getMovePositionIds({ nodes, sameColumn: false, newIndex: nodes.length })).toEqual({
          moveBeforeId: 'gid://gitlab/WorkItem/3',
          moveAfterId: undefined,
        });
      });

      it('returns no ids when the target column is empty', () => {
        expect(getMovePositionIds({ nodes: [], sameColumn: false, newIndex: 0 })).toEqual({
          moveBeforeId: undefined,
          moveAfterId: undefined,
        });
      });
    });
  });
});
