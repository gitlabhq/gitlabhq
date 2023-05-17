import { getParameterValues } from '~/lib/utils/url_utility';

export function memberName(member) {
  // user defined tokens(invites by email) will have email in `name` and will not contain `username`
  return member.username || member.name;
}

export function triggerExternalAlert() {
  return false;
}

export function qualifiesForTasksToBeDone() {
  return getParameterValues('open_modal')[0] === 'invite_members_for_task';
}
