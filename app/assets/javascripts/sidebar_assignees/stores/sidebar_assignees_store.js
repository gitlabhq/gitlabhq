export default class SidebarAssigneesStore {
  constructor(store) {
    const { currentUserId, assignees, rootPath, editable } = store;

    this.currentUserId = currentUserId;
    this.rootPath = rootPath;

    this.selectedUserIds = [];
    this.renderedUsers = [];

    this.loading = false;
    this.editable = editable;

    this.setUsers(assignees);
  }

  addCurrentUserId() {
    this.addUserId(this.currentUserId);
  }

  addUserId(id) {
    // Prevent duplicate user id's from being added
    if (this.selectedUserIds.indexOf(id) === -1) {
      this.selectedUserIds.push(id);
    }
  }

  removeUserId(id) {
    this.selectedUserIds = this.selectedUserIds.filter(uid => uid !== id);
  }

  removeAllUserIds() {
    this.selectedUserIds = [];
  }

  getUserIds() {
    // If there are no ids, that means we have to unassign (which is id = 0)
    return this.selectedUserIds.length > 0 ? this.selectedUserIds : [0];
  }

  setUsers(users) {
    this.renderedUsers = users.map((u) => ({
      id: u.id,
      name: u.name,
      username: u.username,
      avatarUrl: u.avatar_url,
    }));
    this.selectedUserIds = users.map(u => u.id);
  }
}
