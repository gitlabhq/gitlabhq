import { getPagePath } from './lib/utils/common_utils';

export const isInGroupsPage = () => getPagePath() === 'groups';

export const isInProjectPage = () => getPagePath() === 'projects';

export const getProjectSlug = () => {
  if (isInProjectPage()) {
    return document?.body?.dataset?.project;
  }
  return null;
};

export const getGroupSlug = () => {
  if (isInProjectPage() || isInGroupsPage()) {
    return document?.body?.dataset?.group;
  }
  return null;
};
