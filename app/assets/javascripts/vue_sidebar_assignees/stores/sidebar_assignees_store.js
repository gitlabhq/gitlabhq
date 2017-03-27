export default class SidebarAssigneesStore {
  constructor(currentUserId, service, rootPath, editable) {
    this.currentUserId = currentUserId;
    this.service = service;
    this.rootPath = rootPath;
    this.users = [];
    this.saved = true;
    this.loading = false;
    this.editable = editable;
  }

  addUser(id, name = '', username = '', avatarUrl = '', saved = false) {
    this.users.push({
      id,
      name,
      username,
      avatarUrl,
    });

    // !saved means that this user was added to UI but not service
    this.saved = saved;
  }

  addCurrentUser() {
    this.addUser(this.currentUserId);
    this.saveUsers();
  }

  removeUser(id) {
    this.saved = false;
    this.users = this.users.filter(u => u.id !== id);
  }

  saveUsers() {
    const ids = this.users.map(u => u.id);
    // If there are no ids, that means we have to unassign (which is id = 0)
    const payload = ids.length > 0 ? ids : 0;

    this.loading = true;
    this.service.update(payload)
      .then((response) => {
        const data = response.data;
        const assignee = data.assignee;

        this.users = [];

        // TODO: Update this to match backend response
        if (assignee) {
          this.addUser(assignee.id, assignee.name, assignee.username, assignee.avatar_url, true);
        }

        this.saved = true;
        this.loading = false;
      }).catch((err) => {
        this.loading = false;
        // TODO: Add correct error handling
        throw err;
      });
  }
}
