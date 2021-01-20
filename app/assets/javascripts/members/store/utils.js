export const findMember = (state, memberId) =>
  state.members.find((member) => member.id === memberId);
