export default class SidebarAssigneesStore {
  constructor(currentUserId, service) {
    this.currentUserId = currentUserId;
    this.service = service;
    this.users = [];
    this.saved = true;
  }

  addUser(id, name, username, avatarUrl, saved) {
    this.users.push({
      id,
      name,
      username,
      avatarUrl,
    });

    if (!saved) {
      this.saved = false;
    }
  }

  addCurrentUser() {
    this.addUserIds(this.currentUserId);
  }

  removeUser(id) {
    this.saved = false;
    this.users = this.users.filter((u) => u.id !== id);
  }

  saveUsers() {
    const ids = this.users.map((u) => u.id) || 0;

    this.service.update(ids.length > 0 ? ids : 0)
      .then((response) => {
          const data = response.data;
          const assignee = data.assignee;

          this.users = [];

          if (assignee) {
            this.addUser(assignee.id, assignee.name, assignee.username, assignee.avatar_url, true);
          }
          this.saved = true;
        }).catch((err) => {
          console.log(err);
          console.log('error');
        });
  }
}