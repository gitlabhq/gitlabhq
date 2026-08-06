import { orderGroups, reorderGroupIds } from '~/work_items/board/grouping/ordering';

describe('work_items/board/grouping/ordering', () => {
  const groupBy = { property: 'status' };
  const values = [
    { id: 'a', name: 'A' },
    { id: 'b', name: 'B' },
    { id: 'c', name: 'C' },
  ];
  const groupId = (value) => `status:${value.id}`;

  describe('orderGroups', () => {
    describe.each`
      scenario       | groupOrder
      ${'empty'}     | ${[]}
      ${'undefined'} | ${undefined}
      ${'not array'} | ${'nope'}
    `('when groupOrder is $scenario', ({ groupOrder }) => {
      it('returns the values in their incoming (default) order', () => {
        expect(orderGroups({ groupOrder, groupBy, values })).toEqual(values);
      });
    });

    it('reorders known groups to match groupOrder', () => {
      const groupOrder = [groupId(values[2]), groupId(values[0]), groupId(values[1])];

      expect(orderGroups({ groupOrder, groupBy, values })).toEqual([
        values[2],
        values[0],
        values[1],
      ]);
    });

    it('appends groups absent from groupOrder after the ordered ones, in default order', () => {
      // Only c and a are ordered; b (e.g. a newly-added status) falls to the end.
      const groupOrder = [groupId(values[2]), groupId(values[0])];

      expect(orderGroups({ groupOrder, groupBy, values })).toEqual([
        values[2],
        values[0],
        values[1],
      ]);
    });

    it('ignores identifiers in groupOrder that no longer match a value', () => {
      const groupOrder = ['status:stale', groupId(values[1]), groupId(values[0])];

      expect(orderGroups({ groupOrder, groupBy, values })).toEqual([
        values[1],
        values[0],
        values[2],
      ]);
    });

    it('does not mutate the input values array', () => {
      const groupOrder = [groupId(values[2]), groupId(values[0]), groupId(values[1])];
      const input = [...values];

      orderGroups({ groupOrder, groupBy, values: input });

      expect(input).toEqual(values);
    });
  });

  describe('reorderGroupIds', () => {
    it('maps the (already reordered) visible values to their group ids in order', () => {
      const visibleValues = [values[1], values[2], values[0]];

      expect(reorderGroupIds({ visibleValues, allValues: values, groupBy })).toEqual([
        groupId(values[1]),
        groupId(values[2]),
        groupId(values[0]),
      ]);
    });

    it('appends group ids present in allValues but not visible, preserving them', () => {
      const visibleValues = [values[2], values[0]];

      expect(reorderGroupIds({ visibleValues, allValues: values, groupBy })).toEqual([
        groupId(values[2]),
        groupId(values[0]),
        groupId(values[1]),
      ]);
    });

    it('keeps a hidden column at its stored position instead of pushing it to the end', () => {
      const currentOrder = [groupId(values[2]), groupId(values[1]), groupId(values[0])];
      const visibleValues = [values[0], values[1]];

      expect(reorderGroupIds({ visibleValues, allValues: values, groupBy, currentOrder })).toEqual([
        groupId(values[2]),
        groupId(values[0]),
        groupId(values[1]),
      ]);
    });

    it('drops stale ids from currentOrder and appends newly-added columns', () => {
      const currentOrder = ['status:stale', groupId(values[1])];
      const visibleValues = [values[1], values[0]];

      expect(reorderGroupIds({ visibleValues, allValues: values, groupBy, currentOrder })).toEqual([
        groupId(values[1]),
        groupId(values[0]),
        groupId(values[2]),
      ]);
    });
  });
});
