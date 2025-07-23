import { formatGraphQLGroups } from '~/vue_shared/components/groups_list/formatter';

export const formatGroups = (groups) =>
  formatGraphQLGroups(groups, (group) => ({
    editPath: group.editPath,
    avatarLabel: group.name,
  }));
