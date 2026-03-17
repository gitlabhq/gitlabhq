import { joinPaths } from '~/lib/utils/url_utility';
import { n__ } from '~/locale';
import { accessLevelsConfig } from '~/projects/settings/branch_rules/components/constants';

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
  const accessLevelTypes = { total, roles: [], deployKeys: [] };

  (accessLevels.edges || []).forEach(({ node }) => {
    if (node.deployKey) {
      accessLevelTypes.deployKeys.push(node.deployKey);
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

    if (node.deployKey?.id !== undefined) {
      result.deployKeyId = node.deployKey.id;
      delete result.accessLevel; // backend only expects deployKeyId
    }

    return Object.keys(result).length > 0 ? [result] : [];
  });
};

export const getAccessLevelsRolesText = (accessLevels) => {
  if (!accessLevels.roles?.length) {
    return [];
  }

  const roles = accessLevels.roles.map(
    (roleInteger) => accessLevelsConfig[roleInteger].accessLevelLabel,
  );
  return [roles.join(', ')];
};

export const getAccessLevelsDeployKeysText = (accessLevels) => {
  if (!accessLevels.deployKeys?.length) {
    return [];
  }

  return [n__('1 deploy key', '%d deploy keys', accessLevels.deployKeys.length)];
};
