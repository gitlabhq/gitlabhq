export default class GroupsStore {
  constructor() {
    this.state = {};
    this.state.groups = {};
    this.state.pageInfo = {};

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

  storePagination(pagination = {}) {
    let paginationInfo;

    if (Object.keys(pagination).length) {
      const normalizedHeaders = gl.utils.normalizeHeaders(pagination);
      paginationInfo = gl.utils.parseIntPagination(normalizedHeaders);
    } else {
      paginationInfo = pagination;
    }

    this.state.pageInfo = paginationInfo;
  }

  buildTree(rawGroups) {
    const groups = this.decorateGroups(rawGroups);
    const tree = {};
    const mappedGroups = {};
    const orphans = [];

    // Map groups to an object
    for (let i = 0, len = groups.length; i < len; i += 1) {
      const group = groups[i];
      mappedGroups[group.id] = group;
      mappedGroups[group.id].subGroups = {};
    }

    Object.keys(mappedGroups).map((key) => {
      const currentGroup = mappedGroups[key];
      // If the group is not at the root level, add it to its parent array of subGroups.
      const parentGroup = mappedGroups[currentGroup.parentId];
      if (currentGroup.parentId) {
        if (parentGroup) {
          mappedGroups[currentGroup.parentId].subGroups[currentGroup.id] = currentGroup;
          mappedGroups[currentGroup.parentId].isOpen = true; // Expand group if it has subgroups
        } else {
          // Means the groups hast no direct parent.
          // Save for later processing, we will add them to its corresponding base group
          orphans.push(currentGroup);
        }
      } else {
        // If the group is at the root level, add it to first level elements array.
        tree[currentGroup.id] = currentGroup;
      }

      return key;
    });

    // Hopefully this array will be empty for most cases
    if (orphans.length) {
      orphans.map((orphan) => {
        let found = false;
        const currentOrphan = orphan;

        Object.keys(tree).map((key) => {
          const group = tree[key];
          if (currentOrphan.fullPath.lastIndexOf(group.fullPath) === 0) {
            group.subGroups[currentOrphan.id] = currentOrphan;
            group.isOpen = true;
            currentOrphan.isOrphan = true;
            found = true;
          }

          return key;
        });

        if (!found) {
          currentOrphan.isOrphan = true;
          tree[currentOrphan.id] = currentOrphan;
        }

        return orphan;
      });
    }

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
      fullPath: rawGroup.full_path,
      name: rawGroup.name,
      description: rawGroup.description,
      webUrl: rawGroup.web_url,
      parentId: rawGroup.parent_id,
      visibility: rawGroup.visibility,
      isOpen: false,
      isOrphan: false,
      numberProjects: 10,
      numberMembers: 10,
      subGroups: {},
    };
  }

  static toggleSubGroups(toggleGroup) {
    const group = toggleGroup;
    group.isOpen = !group.isOpen;
    return group;
  }
}
