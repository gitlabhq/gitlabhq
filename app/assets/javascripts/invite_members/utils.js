import { parseBoolean } from '~/lib/utils/common_utils';

export function membersProvideData(el) {
  if (!el) {
    return false;
  }

  const {
    name,
    overageMembersModalAvailable,
    hasGitlabSubscription,
    addSeatsHref,
    hasBsoFeatureEnabled,
    searchUrl,
  } = el.dataset;

  return {
    name,
    overageMembersModalAvailable: parseBoolean(overageMembersModalAvailable),
    hasGitlabSubscription: parseBoolean(hasGitlabSubscription),
    addSeatsHref,
    hasBsoEnabled: parseBoolean(hasBsoFeatureEnabled),
    searchUrl,
  };
}

export function groupsProvideData(el) {
  if (!el) {
    return false;
  }

  const {
    freeUsersLimit,
    overageMembersModalAvailable,
    hasGitlabSubscription,
    inviteWithCustomRoleEnabled,
  } = el.dataset;

  return {
    freeUsersLimit: parseInt(freeUsersLimit, 10),
    overageMembersModalAvailable: parseBoolean(overageMembersModalAvailable),
    hasGitlabSubscription: parseBoolean(hasGitlabSubscription),
    inviteWithCustomRoleEnabled: parseBoolean(inviteWithCustomRoleEnabled),
  };
}
