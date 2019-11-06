import axios from '~/lib/utils/axios_utils';

const rootUrl = gon.relative_url_root;

export default function fetchGroupPathAvailability(groupPath) {
  return axios.get(`${rootUrl}/users/${groupPath}/suggests`);
}
