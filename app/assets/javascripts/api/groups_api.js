import { DEFAULT_PER_PAGE } from '~/api';
import axios from '../lib/utils/axios_utils';
import { buildApiUrl } from './api_utils';

const GROUP_PATH = '/api/:version/groups/:id';
const GROUP_RESTORE_PATH = '/api/:version/groups/:id/restore';
const GROUP_ARCHIVE_PATH = '/api/:version/groups/:id/archive';
const GROUPS_PATH = '/api/:version/groups.json';
const GROUP_MEMBERS_PATH = '/api/:version/groups/:id/members';
const GROUP_MEMBER_PATH = '/api/:version/groups/:id/members/:user_id';
const GROUP_ALL_MEMBERS_PATH = '/api/:version/groups/:id/members/all';
const DESCENDANT_GROUPS_PATH = '/api/:version/groups/:id/descendant_groups';
const GROUP_TRANSFER_LOCATIONS_PATH = 'api/:version/groups/:id/transfer_locations';
const SHARED_GROUPS_PATH = 'api/:version/groups/:id/groups/shared';

// eslint-disable-next-line max-params
const axiosGet = (url, query, options, callback, axiosOptions = {}) => {
  return axios
    .get(url, {
      params: {
        search: query,
        per_page: DEFAULT_PER_PAGE,
        ...options,
      },
      ...axiosOptions,
    })
    .then(({ data, headers }) => {
      callback(data);

      return { data, headers };
    });
};

// eslint-disable-next-line max-params
export function getGroups(query, options, callback = () => {}, axiosOptions = {}) {
  const url = buildApiUrl(GROUPS_PATH);
  return axiosGet(url, query, options, callback, axiosOptions);
}

// eslint-disable-next-line max-params
export function getDescendentGroups(
  parentGroupId,
  query,
  options,
  callback = () => {},
  axiosOptions = {},
) {
  const url = buildApiUrl(DESCENDANT_GROUPS_PATH.replace(':id', parentGroupId));
  return axiosGet(url, query, options, callback, axiosOptions);
}

export function updateGroup(groupId, data = {}) {
  const url = buildApiUrl(GROUP_PATH).replace(':id', groupId);

  return axios.put(url, data);
}

export function deleteGroup(groupId) {
  const url = buildApiUrl(GROUP_PATH).replace(':id', groupId);

  return axios.delete(url);
}

export function restoreGroup(groupId) {
  const url = buildApiUrl(GROUP_RESTORE_PATH).replace(':id', groupId);

  return axios.post(url);
}

export function archiveGroup(groupId) {
  const url = buildApiUrl(GROUP_ARCHIVE_PATH).replace(':id', groupId);

  return axios.post(url);
}

export const getGroupTransferLocations = (groupId, params = {}) => {
  const url = buildApiUrl(GROUP_TRANSFER_LOCATIONS_PATH).replace(':id', groupId);
  const defaultParams = { per_page: DEFAULT_PER_PAGE };

  return axios.get(url, { params: { ...defaultParams, ...params } });
};

export const getGroupMembers = (groupId, inherited = false, params = {}) => {
  const path = inherited ? GROUP_ALL_MEMBERS_PATH : GROUP_MEMBERS_PATH;
  const url = buildApiUrl(path).replace(':id', groupId);

  return axios.get(url, { params });
};

export const deleteGroupMember = (groupId, userId) => {
  const url = buildApiUrl(GROUP_MEMBER_PATH).replace(':id', groupId).replace(':user_id', userId);

  return axios.delete(url);
};

export const createGroup = (params) => {
  const url = buildApiUrl(GROUPS_PATH);
  return axios.post(url, params);
};

export const getSharedGroups = (groupId, params = {}) => {
  const url = buildApiUrl(SHARED_GROUPS_PATH).replace(':id', groupId);
  const defaultParams = { per_page: DEFAULT_PER_PAGE };

  return axios.get(url, { params: { ...defaultParams, ...params } });
};

// no-op: See EE code for implementation
export const fetchGroupEnterpriseUsers = () => {};
