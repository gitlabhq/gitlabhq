import { DEFAULT_PER_PAGE } from '~/api';
import axios from '~/lib/utils/axios_utils';

export function memberName(member) {
  // user defined tokens(invites by email) will have email in `name` and will not contain `username`
  return member.username || member.name;
}

export function searchUsers(url, search) {
  return axios.get(url, {
    params: {
      search,
      per_page: DEFAULT_PER_PAGE,
    },
  });
}

export function triggerExternalAlert() {
  return false;
}

export function baseBindingAttributes() {
  return {};
}
