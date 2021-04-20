import axios from 'axios';
import { getJwt } from '~/jira_connect/utils';

export const addSubscription = async (addPath, namespace) => {
  const jwt = await getJwt();

  return axios.post(addPath, {
    jwt,
    namespace_path: namespace,
  });
};

export const removeSubscription = async (removePath) => {
  const jwt = await getJwt();

  return axios.delete(removePath, {
    params: {
      jwt,
    },
  });
};

export const fetchGroups = async (groupsPath, { page, perPage, search }) => {
  return axios.get(groupsPath, {
    params: {
      page,
      per_page: perPage,
      search,
    },
  });
};
