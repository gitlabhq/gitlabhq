import axios from '~/lib/utils/axios_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import { getGroupMembers } from '~/rest_api';

const GROUP_SUBGROUPS_PATH = '/-/autocomplete/group_subgroups.json';

const buildUrl = (urlRoot, url) => {
  return joinPaths(urlRoot, url);
};

const defaultOptions = {
  includeParentDescendants: false,
  includeParentSharedGroups: false,
  search: '',
};

export const getSubGroups = (options = defaultOptions) => {
  const { includeParentDescendants, includeParentSharedGroups, search } = options;

  return axios.get(buildUrl(gon.relative_url_root || '', GROUP_SUBGROUPS_PATH), {
    params: {
      group_id: gon.current_group_id,
      include_parent_descendants: includeParentDescendants,
      include_parent_shared_groups: includeParentSharedGroups,
      search,
    },
  });
};

export const getUsers = (query) => {
  return getGroupMembers(gon.current_group_id, false, {
    query,
    per_page: 20,
  });
};
