import {
  GROUP_NONE,
  getGroupKey,
  getGroupId,
  getMovePositionIds,
  boardColumnQueryVariables,
} from '~/work_items/board/utils';

describe('work item board utils', () => {
  describe('boardColumnQueryVariables', () => {
    const baseQueryVariables = { state: 'opened', sort: 'CREATED_DESC' };

    it('merges the column filter over the base variables and adds paging', () => {
      expect(
        boardColumnQueryVariables({
          rootPageFullPath: 'full/path',
          baseQueryVariables,
          columnFilter: { status: { name: 'To do' } },
        }),
      ).toEqual({
        fullPath: 'full/path',
        state: 'opened',
        sort: 'CREATED_DESC',
        firstPageSize: 20,
        status: { name: 'To do' },
      });
    });

    it('lets the column filter override colliding base variables', () => {
      expect(
        boardColumnQueryVariables({
          rootPageFullPath: 'full/path',
          baseQueryVariables: { ...baseQueryVariables, status: { name: 'overridden' } },
          columnFilter: { status: { name: 'To do' } },
        }),
      ).toMatchObject({ status: { name: 'To do' } });
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

  describe('getGroupKey', () => {
    it('returns the grouping property when there is no sub-key', () => {
      expect(getGroupKey({ property: 'status' })).toBe('status');
    });

    it('appends the sub-key for parameterized groupings (for example custom fields)', () => {
      expect(getGroupKey({ property: 'custom_field', key: 'gid://gitlab/Field/7' })).toBe(
        'custom_field.gid://gitlab/Field/7',
      );
    });
  });

  describe('getGroupId', () => {
    const groupBy = { property: 'status' };

    it('builds a grouping-scoped id from the value Global ID', () => {
      const value = { id: 'gid://gitlab/WorkItems::Statuses::SystemDefined::Status/1' };

      expect(getGroupId({ groupBy, value })).toBe(
        'status:gid://gitlab/WorkItems::Statuses::SystemDefined::Status/1',
      );
    });

    it('uses the none sentinel for the null/unassigned bucket', () => {
      expect(getGroupId({ groupBy, value: null })).toBe(`status:${GROUP_NONE}`);
      expect(getGroupId({ groupBy, value: {} })).toBe(`status:${GROUP_NONE}`);
    });

    it('scopes the id by grouping so the same value id differs across groupings', () => {
      const value = { id: 'gid://gitlab/Label/5' };

      expect(getGroupId({ groupBy: { property: 'label' }, value })).toBe(
        'label:gid://gitlab/Label/5',
      );
      expect(getGroupId({ groupBy: { property: 'status' }, value })).toBe(
        'status:gid://gitlab/Label/5',
      );
    });
  });
});
