import { DEFAULT_PER_PAGE } from '~/api';
import axios from '~/lib/utils/axios_utils';
import { toNounSeriesText } from '~/lib/utils/grammar';

export function memberName(member) {
  // user defined tokens(invites by email) will have email in `name` and will not contain `username`
  return member.username || member.name;
}

export function groupErrorsByMessage(invalidMembers, toDisplayName) {
  const groups = new Map();

  Object.entries(invalidMembers).forEach(([member, message]) => {
    if (!groups.has(message)) {
      groups.set(message, []);
    }

    groups.get(message).push(member);
  });

  return Array.from(groups, ([message, members]) => ({
    id: members.join(','),
    displayedMemberNames: toNounSeriesText(members.map(toDisplayName).filter(Boolean)),
    message,
  }));
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
