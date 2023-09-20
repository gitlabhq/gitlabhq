import Api from '~/api';
import axios from '~/lib/utils/axios_utils';
import { ACCESS_LEVEL_DEVELOPER_INTEGER } from '~/access_level/constants';

const GROUPS_PATH = '/-/autocomplete/project_groups.json';
const USERS_PATH = '/-/autocomplete/users.json';
const DEPLOY_KEYS_PATH = '/-/autocomplete/deploy_keys_with_owners.json';

const buildUrl = (urlRoot, url) => {
  let newUrl;
  if (urlRoot != null) {
    newUrl = urlRoot.replace(/\/$/, '') + url;
  }
  return newUrl;
};

export const getUsers = (query, states) => {
  return axios.get(buildUrl(gon.relative_url_root || '', USERS_PATH), {
    params: {
      search: query,
      per_page: 20,
      active: true,
      project_id: gon.current_project_id,
      push_code: true,
      states,
    },
  });
};

export const getGroups = () => {
  if (gon.current_project_id) {
    return Api.projectGroups(gon.current_project_id, {
      with_shared: true,
      shared_min_access_level: ACCESS_LEVEL_DEVELOPER_INTEGER,
    });
  }
  return axios.get(buildUrl(gon.relative_url_root || '', GROUPS_PATH)).then(({ data }) => {
    return data;
  });
};

export const getDeployKeys = (query) => {
  return axios.get(buildUrl(gon.relative_url_root || '', DEPLOY_KEYS_PATH), {
    params: {
      search: query,
      per_page: 20,
      active: true,
      project_id: gon.current_project_id,
      push_code: true,
    },
  });
};
