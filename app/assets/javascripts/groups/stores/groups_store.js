export default class GroupsStore {
  constructor() {
    this.state = {};
    this.state.groups = [];

    return this;
  }

  setGroups(group, groups) {
    if (group) {
      // const group = this.state.groups.find();
    } else {
      this.state.groups = this.decorateGroups(groups);
    }

    return groups;
  }

  decorateGroups(rawGroups) {
    this.groups = rawGroups.map(GroupsStore.decorateGroup);
    return this.groups;
  }

  static decorateGroup(rawGroup) {
    const group = rawGroup;
    group.isOpen = false;
    return group;
  }

  static toggleSubGroups(toggleGroup) {
    const group = toggleGroup;
    group.isOpen = !group.isOpen;
    return group;
  }
}
