import Vue from 'vue';

export default class GroupsStore {
  constructor() {
    this.state = {};
    this.state.groups = {};
    this.state.pageInfo = {};
  }

  setGroups(rawGroups, parent) {
    const parentGroup = parent;
    const tree = this.buildTree(rawGroups, parentGroup);

    if (parentGroup) {
      parentGroup.subGroups = tree;
    } else {
      this.state.groups = tree;
    }

    return tree;
  }

  // eslint-disable-next-line class-methods-use-this
  resetGroups(parent) {
    const parentGroup = parent;
    parentGroup.subGroups = {};
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

  buildTree(rawGroups, parentGroup) {
    const groups = this.decorateGroups(rawGroups);
    const tree = {};
    const mappedGroups = {};
    const orphans = [];

    // Map groups to an object
    groups.map((group) => {
      mappedGroups[`id${group.id}`] = group;
      mappedGroups[`id${group.id}`].subGroups = {};
      return group;
    });

    Object.keys(mappedGroups).map((key) => {
      const currentGroup = mappedGroups[key];
      if (currentGroup.parentId) {
        // If the group is not at the root level, add it to its parent array of subGroups.
        const findParentGroup = mappedGroups[`id${currentGroup.parentId}`];
        if (findParentGroup) {
          mappedGroups[`id${currentGroup.parentId}`].subGroups[`id${currentGroup.id}`] = currentGroup;
          mappedGroups[`id${currentGroup.parentId}`].isOpen = true; // Expand group if it has subgroups
        } else if (parentGroup && parentGroup.id === currentGroup.parentId) {
          tree[`id${currentGroup.id}`] = currentGroup;
        } else {
          // No parent found. We save it for later processing
          orphans.push(currentGroup);

          // Add to tree to preserve original order
          tree[`id${currentGroup.id}`] = currentGroup;
        }
      } else {
        // If the group is at the top level, add it to first level elements array.
        tree[`id${currentGroup.id}`] = currentGroup;
      }

      return key;
    });

    if (orphans.length) {
      orphans.map((orphan) => {
        let found = false;
        const currentOrphan = orphan;

        Object.keys(tree).map((key) => {
          const group = tree[key];

          if (
           group &&
           currentOrphan.fullPath.lastIndexOf(group.fullPath) === 0 &&
           // Make sure the currently selected orphan is not the same as the group
           // we are checking here otherwise it will end up in an infinite loop
           currentOrphan.id !== group.id
           ) {
            group.subGroups[currentOrphan.id] = currentOrphan;
            group.isOpen = true;
            currentOrphan.isOrphan = true;
            found = true;

            // Delete if group was put at the top level. If not the group will be displayed twice.
            if (tree[`id${currentOrphan.id}`]) {
              delete tree[`id${currentOrphan.id}`];
            }
          }

          return key;
        });

        if (!found) {
          currentOrphan.isOrphan = true;

          tree[`id${currentOrphan.id}`] = currentOrphan;
        }

        return orphan;
      });
    }

    return tree;
  }

  decorateGroups(rawGroups) {
    this.groups = rawGroups.map(this.decorateGroup);
    return this.groups;
  }

  // eslint-disable-next-line class-methods-use-this
  decorateGroup(rawGroup) {
    return {
      id: rawGroup.id,
      fullName: rawGroup.full_name,
      fullPath: rawGroup.full_path,
      avatarUrl: rawGroup.avatar_url,
      name: rawGroup.name,
      hasSubgroups: rawGroup.has_subgroups,
      canEdit: rawGroup.can_edit,
      description: rawGroup.description,
      webUrl: rawGroup.web_url,
      groupPath: rawGroup.group_path,
      parentId: rawGroup.parent_id,
      visibility: rawGroup.visibility,
      leavePath: rawGroup.leave_path,
      editPath: rawGroup.edit_path,
      isOpen: false,
      isOrphan: false,
      numberProjects: rawGroup.number_projects_with_delimiter,
      numberUsers: rawGroup.number_users_with_delimiter,
      permissions: {
        humanGroupAccess: rawGroup.permissions.human_group_access,
      },
      subGroups: {},
    };
  }

  // eslint-disable-next-line class-methods-use-this
  removeGroup(group, collection) {
    Vue.delete(collection, `id${group.id}`);
  }

  // eslint-disable-next-line class-methods-use-this
  toggleSubGroups(toggleGroup) {
    const group = toggleGroup;
    group.isOpen = !group.isOpen;
    return group;
  }
}
