import {
  effectiveVisibleGroups,
  exceedsGroupLimit,
  isGroupVisible,
  toggleGroupVisibility,
} from '~/work_items/board/grouping/visibility';

describe('work_items/board/grouping/visibility', () => {
  const groupBy = { property: 'status' };
  const values = [
    { id: 'a', name: 'A' },
    { id: 'b', name: 'B' },
    { id: 'c', name: 'C' },
  ];
  const groupId = (value) => `status:${value.id}`;

  describe('isGroupVisible', () => {
    describe.each`
      scenario       | visibleGroups
      ${'null'}      | ${null}
      ${'undefined'} | ${undefined}
    `('when visibleGroups is $scenario', ({ visibleGroups }) => {
      it('returns true for every value', () => {
        values.forEach((value) => {
          expect(isGroupVisible(visibleGroups, groupBy, value)).toBe(true);
        });
      });
    });

    describe('when visibleGroups is an explicit list', () => {
      const visibleGroups = [groupId(values[0])];

      it('returns true for a value in the list', () => {
        expect(isGroupVisible(visibleGroups, groupBy, values[0])).toBe(true);
      });

      it('returns false for a value missing from the list', () => {
        expect(isGroupVisible(visibleGroups, groupBy, values[1])).toBe(false);
      });
    });
  });

  describe('exceedsGroupLimit', () => {
    it.each`
      groupCount | expected
      ${0}       | ${false}
      ${25}      | ${false}
      ${26}      | ${true}
    `('returns $expected for $groupCount groups', ({ groupCount, expected }) => {
      expect(exceedsGroupLimit(groupCount)).toBe(expected);
    });
  });

  describe('effectiveVisibleGroups', () => {
    describe('when visibleGroups is null', () => {
      it('stays null while the group count is within the limit', () => {
        expect(effectiveVisibleGroups(null, 25)).toBeNull();
      });

      it('becomes an empty list once the group count passes the limit', () => {
        expect(effectiveVisibleGroups(null, 26)).toEqual([]);
      });
    });

    describe('when visibleGroups is an explicit list', () => {
      it('returns the list unchanged whatever the group count', () => {
        const visibleGroups = [groupId(values[0])];

        expect(effectiveVisibleGroups(visibleGroups, 26)).toBe(visibleGroups);
      });
    });
  });

  describe('toggleGroupVisibility', () => {
    describe('when every group is visible', () => {
      it('excludes the toggled value', () => {
        expect(
          toggleGroupVisibility({
            visibleGroups: null,
            groupBy,
            value: values[1],
            allValues: values,
          }),
        ).toEqual([groupId(values[0]), groupId(values[2])]);
      });
    });

    describe('when the last hidden group is toggled back on', () => {
      let afterFirstToggle;

      beforeEach(() => {
        afterFirstToggle = toggleGroupVisibility({
          visibleGroups: null,
          groupBy,
          value: values[1],
          allValues: values,
        });
      });

      it('collapses back to null', () => {
        expect(
          toggleGroupVisibility({
            visibleGroups: afterFirstToggle,
            groupBy,
            value: values[1],
            allValues: values,
          }),
        ).toBeNull();
      });
    });

    describe('when visibleGroups is an explicit list', () => {
      const visibleGroups = [groupId(values[0]), groupId(values[1])];

      it('adds a hidden value to the list', () => {
        expect(
          toggleGroupVisibility({
            visibleGroups: [groupId(values[0])],
            groupBy,
            value: values[1],
            allValues: values,
          }),
        ).toEqual([groupId(values[0]), groupId(values[1])]);
      });

      it('removes a visible value from the list', () => {
        expect(
          toggleGroupVisibility({ visibleGroups, groupBy, value: values[0], allValues: values }),
        ).toEqual([groupId(values[1])]);
      });

      it('returns an empty list, not null, when the last visible value is removed', () => {
        expect(
          toggleGroupVisibility({
            visibleGroups: [groupId(values[0])],
            groupBy,
            value: values[0],
            allValues: values,
          }),
        ).toEqual([]);
      });
    });
  });
});
