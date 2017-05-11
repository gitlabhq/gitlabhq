export default class GroupsStore {
  constructor() {
    this.state = {};
    this.state.groups = [];

    return this;
  }

  setGroups(groups) {
    this.state.groups = this.decorateGroups(groups);

    return groups;
  }

  decorateGroups(rawGroups) {
    this.groups = rawGroups.map(GroupsStore.decorateGroup);
    return this.groups;
  }

  static decorateGroup(rawGroup) {
    return {
      fullName: rawGroup.name,
      description: rawGroup.description,
      webUrl: rawGroup.web_url,
      parentId: rawGroup.parentId,
      hasSubgroups: !!rawGroup.parent_id,
      isOpen: false,
    };
  }

  static toggleSubGroups(toggleGroup) {
    const group = toggleGroup;
    group.isOpen = !group.isOpen;
    return group;
  }
}
