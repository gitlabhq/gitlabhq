import { isUndefined } from 'lodash';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import {
  GROUP_MEMBER_BASE_PROPERTY_NAME,
  GROUP_MEMBER_ACCESS_LEVEL_PROPERTY_NAME,
  GROUP_LINK_BASE_PROPERTY_NAME,
  GROUP_LINK_ACCESS_LEVEL_PROPERTY_NAME,
} from './constants';

export const parseDataAttributes = el => {
  const { members, groupId, memberPath, canManageMembers } = el.dataset;

  return {
    members: convertObjectPropsToCamelCase(JSON.parse(members), { deep: true }),
    sourceId: parseInt(groupId, 10),
    memberPath,
    canManageMembers: parseBoolean(canManageMembers),
  };
};

const baseRequestFormatter = (basePropertyName, accessLevelPropertyName) => ({
  accessLevel,
  ...otherProperties
}) => {
  const accessLevelProperty = !isUndefined(accessLevel)
    ? { [accessLevelPropertyName]: accessLevel }
    : {};

  return {
    [basePropertyName]: {
      ...accessLevelProperty,
      ...otherProperties,
    },
  };
};

export const memberRequestFormatter = baseRequestFormatter(
  GROUP_MEMBER_BASE_PROPERTY_NAME,
  GROUP_MEMBER_ACCESS_LEVEL_PROPERTY_NAME,
);

export const groupLinkRequestFormatter = baseRequestFormatter(
  GROUP_LINK_BASE_PROPERTY_NAME,
  GROUP_LINK_ACCESS_LEVEL_PROPERTY_NAME,
);
