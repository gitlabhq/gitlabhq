import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export const parseDataAttributes = el => {
  const { members, groupId, memberPath } = el.dataset;

  return {
    members: convertObjectPropsToCamelCase(JSON.parse(members), { deep: true }),
    sourceId: parseInt(groupId, 10),
    memberPath,
  };
};
