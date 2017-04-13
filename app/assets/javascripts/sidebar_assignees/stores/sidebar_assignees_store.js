export default class SidebarAssigneesStore {
  constructor(store) {
    const { currentUserId, assignees, rootPath, editable } = store;

    this.currentUserId = currentUserId;
    this.rootPath = rootPath;

    // Tracks the selected users
    this.userIds = [];

    // Tracks the rendered users
    this.users = [];

    this.loading = false;
    this.editable = editable;

    this.setUsers(assignees);

    this.userIds = assignees.map(a => a.id);
  }

  addUserId(id) {
    this.userIds.push(id);
  }

  removeUserId(id) {
    this.userIds = this.userIds.filter(uid => uid !== id);
  }

  removeAllUserIds() {
    this.userIds = [];
  }

  addCurrentUserId() {
    this.addUserId(this.currentUserId);
  }

  getUserIds() {
    // If there are no ids, that means we have to unassign (which is id = 0)
    return this.userIds.length > 0 ? this.userIds : [0];
  }

  setUsers(users) {
    this.users = users.map((u) => ({
      id: u.id,
      name: u.name,
      username: u.username,
      avatarUrl: u.avatar_url,
    }));
  }
}
