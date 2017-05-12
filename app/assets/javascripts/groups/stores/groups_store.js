export default class GroupsStore {
  constructor() {
    this.state = {};
    this.state.groups = {};

    return this;
  }

  setGroups(rawGroups, parent = null) {
    const parentGroup = parent;

    if (parentGroup) {
      parentGroup.subGroups = this.buildTree(rawGroups);
    } else {
      this.state.groups = this.buildTree(rawGroups);
    }

    return rawGroups;
  }

  buildTree(rawGroups) {
    const groups = this.decorateGroups(rawGroups);
    const tree = {};
    const mappedGroups = {};

    // Map groups to an object
    for (let i = 0, len = groups.length; i < len; i += 1) {
      const group = groups[i];
      mappedGroups[group.id] = group;
      mappedGroups[group.id].subGroups = {};
    }

    Object.keys(mappedGroups).forEach((key) => {
      const currentGroup = mappedGroups[key];
      // If the group is not at the root level, add it to its parent array of subGroups.
      if (currentGroup.parentId) {
        mappedGroups[currentGroup.parentId].subGroups[currentGroup.id] = currentGroup;
        mappedGroups[currentGroup.parentId].isOpen = true; // Expand group if it has subgroups
      } else {
        // If the group is at the root level, add it to first level elements array.
        tree[currentGroup.id] = currentGroup;
      }
    });

    return tree;
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
      expandable: true,
      isOpen: false,
      subGroups: {},
    };
  }

  static toggleSubGroups(toggleGroup) {
    const group = toggleGroup;
    group.isOpen = !group.isOpen;
    return group;
  }
}
