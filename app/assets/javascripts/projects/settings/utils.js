export const getAccessLevels = (accessLevels = {}) => {
  const total = accessLevels.edges?.length;
  const accessLevelTypes = { total, users: [], groups: [], roles: [] };

  accessLevels.edges?.forEach(({ node }) => {
    if (node.user) {
      const src = node.user.avatarUrl;
      accessLevelTypes.users.push({ src, ...node.user });
    } else if (node.group) {
      accessLevelTypes.groups.push(node);
    } else {
      accessLevelTypes.roles.push({ accessLevelDescription: node.accessLevelDescription });
    }
  });

  return accessLevelTypes;
};
