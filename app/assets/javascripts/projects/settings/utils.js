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
