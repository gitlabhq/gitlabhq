import axios from 'axios';
import { buildApiUrl } from '~/api/api_utils';

import { GITLAB_COM_BASE_PATH } from '~/jira_connect/subscriptions/constants';
import { getJwt } from './utils';

const CURRENT_USER_PATH = '/api/:version/user';
const JIRA_CONNECT_SUBSCRIPTIONS_PATH = '/api/:version/integrations/jira_connect/subscriptions';
const JIRA_CONNECT_INSTALLATIONS_PATH = '/-/jira_connect/installations';
const JIRA_CONNECT_OAUTH_APPLICATION_ID_PATH = '/-/jira_connect/oauth_application_id';

// This export is only used for testing purposes
export const axiosInstance = axios.create();

export const setApiBaseURL = (baseURL = null) => {
  axiosInstance.defaults.baseURL = baseURL;
};

export const removeSubscription = async (removePath) => {
  const jwt = await getJwt();

  return axiosInstance.delete(removePath, {
    params: {
      jwt,
    },
  });
};

export const fetchGroups = async (
  groupsPath,
  { minAccessLevel, page, perPage, search },
  accessToken = null,
) => {
  return axiosInstance.get(groupsPath, {
    params: {
      min_access_level: minAccessLevel,
      page,
      per_page: perPage,
      search,
    },
    headers: {
      ...(accessToken ? { Authorization: `Bearer ${accessToken}` } : {}),
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

export const updateInstallation = async (instanceUrl) => {
  const jwt = await getJwt();

  return axiosInstance.put(JIRA_CONNECT_INSTALLATIONS_PATH, {
    jwt,
    installation: {
      instance_url: instanceUrl === GITLAB_COM_BASE_PATH ? null : instanceUrl,
    },
  });
};

export const fetchOAuthApplicationId = () => {
  return axiosInstance.get(JIRA_CONNECT_OAUTH_APPLICATION_ID_PATH);
};

export const fetchOAuthToken = (oauthTokenPath, data = {}) => {
  return axiosInstance.post(oauthTokenPath, data);
};
