import { isObject } from 'lodash';
import Api from '~/api';

/**
 * @param {'descendant_groups'|'subgroups'|null} [groupsFilter] - type of group filtering
 * @param {string|null} [parentGroupID] - parent group is needed for 'descendant_groups' and 'subgroups' filtering.
 */
export const groupsPath = (groupsFilter, parentGroupID) => {
  if (groupsFilter && !parentGroupID) {
    throw new Error('Cannot use groupsFilter without a parentGroupID');
  }

  let url = '';
  switch (groupsFilter) {
    case 'descendant_groups':
      url = Api.descendantGroupsPath.replace(':id', parentGroupID);
      break;
    case 'subgroups':
      url = Api.subgroupsPath.replace(':id', parentGroupID);
      break;
    default:
      url = Api.groupsPath;
      break;
  }

  return Api.buildUrl(url);
};

export const initialSelectionPropValidator = (value) => {
  if (!isObject(value)) {
    return true;
  }

  return value.text !== undefined && value.value !== undefined;
};
