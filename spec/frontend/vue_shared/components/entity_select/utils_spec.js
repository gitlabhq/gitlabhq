import { groupsPath } from '~/vue_shared/components/entity_select/utils';

describe('entity_select utils', () => {
  describe('groupsPath', () => {
    it.each`
      groupsFilter           | parentGroupID | expectedPath
      ${undefined}           | ${undefined}  | ${'/api/:version/groups.json'}
      ${undefined}           | ${1}          | ${'/api/:version/groups.json'}
      ${'descendant_groups'} | ${1}          | ${'/api/:version/groups/1/descendant_groups'}
      ${'subgroups'}         | ${1}          | ${'/api/:version/groups/1/subgroups'}
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
});
