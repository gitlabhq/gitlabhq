import {
  groupsPath,
  initialSelectionPropValidator,
} from '~/vue_shared/components/entity_select/utils';

describe('entity_select utils', () => {
  describe('groupsPath', () => {
    beforeEach(() => {
      window.gon = { api_version: 'v4' };
    });

    it.each`
      groupsFilter           | parentGroupID | expectedPath
      ${undefined}           | ${undefined}  | ${'/api/v4/groups.json'}
      ${undefined}           | ${1}          | ${'/api/v4/groups.json'}
      ${'descendant_groups'} | ${1}          | ${'/api/v4/groups/1/descendant_groups'}
      ${'subgroups'}         | ${1}          | ${'/api/v4/groups/1/subgroups'}
    `(
      'returns $expectedPath with groupsFilter = $groupsFilter and parentGroupID = $parentGroupID',
      ({ groupsFilter, parentGroupID, expectedPath }) => {
        expect(groupsPath(groupsFilter, parentGroupID)).toBe(expectedPath);
      },
    );
  });

  it('throws if groupsFilter is passed but parentGroupID is undefined', () => {
    expect(() => {
      groupsPath('descendant_groups');
    }).toThrow('Cannot use groupsFilter without a parentGroupID');
  });

  describe('initialSelectionPropValidator', () => {
    it.each`
      value                            | expected
      ${1}                             | ${true}
      ${'1'}                           | ${true}
      ${{ value: 'foo', text: 'Bar' }} | ${true}
      ${{ text: 'Bar' }}               | ${false}
      ${{ value: 'foo' }}              | ${false}
    `('returns $expected when value is $value', ({ value, expected }) => {
      expect(initialSelectionPropValidator(value)).toBe(expected);
    });
  });
});
