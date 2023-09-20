export function memberName(member) {
  // user defined tokens(invites by email) will have email in `name` and will not contain `username`
  return member.username || member.name;
}

export function triggerExternalAlert() {
  return false;
}
