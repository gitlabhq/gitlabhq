import { joinPaths } from '~/lib/utils/url_utility';

export const generateRefDestinationPath = (selectedRef) => {
  const namespace = '-/settings/ci_cd';
  const { pathname } = window.location;

  if (!selectedRef || !pathname.includes(namespace)) {
    return window.location.href;
  }

  const [projectRootPath] = pathname.split(namespace);

  const destinationPath = joinPaths(projectRootPath, namespace);

  const newURL = new URL(window.location);
  newURL.pathname = destinationPath;
  newURL.searchParams.set('ref', selectedRef);

  return newURL.href;
};

export const getAccessLevels = (accessLevels = {}) => {
  const total = accessLevels.edges?.length;
  const accessLevelTypes = { total, users: [], groups: [], roles: [] };

  (accessLevels.edges || []).forEach(({ node }) => {
    if (node.user) {
      const src = node.user.avatarUrl;
      accessLevelTypes.users.push({ src, ...node.user });
    } else if (node.group) {
      accessLevelTypes.groups.push(node.group);
    } else {
      accessLevelTypes.roles.push(node.accessLevel);
    }
  });

  return accessLevelTypes;
};

export const getAccessLevelInputFromEdges = (edges) => {
  return edges.flatMap(({ node }) => {
    const result = {};

    if (node.accessLevel !== undefined) {
      result.accessLevel = node.accessLevel;
    }

    if (node.group?.id !== undefined) {
      result.groupId = node.group.id;
      delete result.accessLevel; // backend only expects groupId
    }

    if (node.user?.id !== undefined) {
      result.userId = node.user.id;
      delete result.accessLevel; // backend only expects userId
    }

    return Object.keys(result).length > 0 ? [result] : [];
  });
};
