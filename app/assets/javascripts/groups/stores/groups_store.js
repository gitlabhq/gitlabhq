export default class GroupsStore {
  constructor() {
    this.state = {};
    this.state.groups = [];

    return this;
  }

  setGroups(groups) {
    this.state.groups = groups;

    return groups;
  }
}
