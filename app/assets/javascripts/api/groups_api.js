import axios from '../lib/utils/axios_utils';
import { buildApiUrl } from './api_utils';
import { DEFAULT_PER_PAGE } from './constants';

const GROUPS_PATH = '/api/:version/groups.json';
const GROUPS_MEMBERS_SINGLE_PATH = '/api/:version/groups/:group_id/members/:id';

export function getGroups(query, options, callback = () => {}) {
  const url = buildApiUrl(GROUPS_PATH);
  return axios
    .get(url, {
      params: {
        search: query,
        per_page: DEFAULT_PER_PAGE,
        ...options,
      },
    })
    .then(({ data }) => {
      callback(data);

      return data;
    });
}

export function removeMemberFromGroup(groupId, memberId, options) {
  const url = buildApiUrl(GROUPS_MEMBERS_SINGLE_PATH)
    .replace(':group_id', groupId)
    .replace(':id', memberId);

  return axios.delete(url, { params: { ...options } });
}
