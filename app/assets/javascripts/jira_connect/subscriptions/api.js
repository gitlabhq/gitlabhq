import axios from 'axios';
import { buildApiUrl } from '~/api/api_utils';

import { getJwt } from './utils';

const CURRENT_USER_PATH = '/api/:version/user';
const JIRA_CONNECT_SUBSCRIPTIONS_PATH = '/api/:version/integrations/jira_connect/subscriptions';

export const axiosInstance = axios.create();

export const addSubscription = async (addPath, namespace) => {
  const jwt = await getJwt();

  return axiosInstance.post(addPath, {
    jwt,
    namespace_path: namespace,
  });
};

export const removeSubscription = async (removePath) => {
  const jwt = await getJwt();

  return axiosInstance.delete(removePath, {
    params: {
      jwt,
    },
  });
};

export const fetchGroups = async (groupsPath, { page, perPage, search }) => {
  return axiosInstance.get(groupsPath, {
    params: {
      page,
      per_page: perPage,
      search,
    },
  });
};

export const fetchSubscriptions = async (subscriptionsPath) => {
  const jwt = await getJwt();

  return axiosInstance.get(subscriptionsPath, {
    params: {
      jwt,
    },
  });
};

export const getCurrentUser = (options) => {
  const url = buildApiUrl(CURRENT_USER_PATH);
  return axiosInstance.get(url, { ...options });
};

export const addJiraConnectSubscription = (namespacePath, { jwt, accessToken }) => {
  const url = buildApiUrl(JIRA_CONNECT_SUBSCRIPTIONS_PATH);

  return axiosInstance.post(
    url,
    {
      jwt,
      namespace_path: namespacePath,
    },
    {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    },
  );
};
