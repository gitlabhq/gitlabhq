export default class GroupsStore {
  constructor() {
    this.state = {};
    this.state.groups = [];

    return this;
  }

  setGroups(rawGroups, parent = null) {
    const parentGroup = parent;

    if (parentGroup) {
      parentGroup.subGroups = this.decorateGroups(rawGroups);
    } else {
      this.state.groups = this.decorateGroups(rawGroups);
    }

    return rawGroups;
  }

  decorateGroups(rawGroups) {
    this.groups = rawGroups.map(GroupsStore.decorateGroup);
    return this.groups;
  }

  static decorateGroup(rawGroup) {
    return {
      id: rawGroup.id,
      fullName: rawGroup.full_name,
      description: rawGroup.description,
      webUrl: rawGroup.web_url,
      parentId: rawGroup.parent_id,
      visibility: rawGroup.visibility,
      isOpen: false,
      numberProjects: 10,
      numberMembers: 10,
      subGroups: [],
    };
  }

  static toggleSubGroups(toggleGroup) {
    const group = toggleGroup;
    group.isOpen = !group.isOpen;
    return group;
  }
}
