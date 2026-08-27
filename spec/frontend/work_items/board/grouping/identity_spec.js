import { GROUP_NONE, getGroupKey, getGroupId } from '~/work_items/board/grouping/identity';

describe('work item board grouping identity', () => {
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
