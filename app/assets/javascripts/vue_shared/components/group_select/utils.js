import Api from '~/api';

export const groupsPath = (groupsFilter, parentGroupID) => {
  if (groupsFilter !== undefined && parentGroupID === undefined) {
    throw new Error('Cannot use groupsFilter without a parentGroupID');
  }
  switch (groupsFilter) {
    case 'descendant_groups':
      return Api.descendantGroupsPath.replace(':id', parentGroupID);
    case 'subgroups':
      return Api.subgroupsPath.replace(':id', parentGroupID);
    default:
      return Api.groupsPath;
  }
};
