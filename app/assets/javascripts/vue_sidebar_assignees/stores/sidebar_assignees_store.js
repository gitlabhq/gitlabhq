/* global Flash */
import '~/flash';

export default class SidebarAssigneesStore {
  constructor(store) {
    const { currentUserId, service, rootPath, editable } = store;

    this.currentUserId = currentUserId;
    this.service = service;
    this.rootPath = rootPath;
    this.users = [];
    this.saved = true;
    this.loading = false;
    this.editable = editable;
    this.defaultRenderCount = 5;
  }

  addUser(user, saved = false) {
    const { id, name, username, avatarUrl } = user;

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
    this.addUser({
      id: this.currentUserId,
    });
    this.saveUsers();
  }

  removeUser(id) {
    this.saved = false;
    this.users = this.users.filter(u => u.id !== id);
  }

  saveUsers() {
    const ids = this.users.map(u => u.id);
    // If there are no ids, that means we have to unassign (which is id = 0)
    const payload = ids.length > 0 ? ids : [0];

    this.loading = true;
    this.service.update(payload)
      .then((response) => {
        const data = response.data;
        const assignees = data.assignees;

        this.users = [];

        assignees.forEach(a => this.addUser({
          id: a.id,
          name: a.name,
          username: a.username,
          avatarUrl: a.avatar_url,
        }, true));

        this.saved = true;
        this.loading = false;
      }).catch(() => {
        this.loading = false;
        return new Flash('An error occured while saving assignees', 'alert');
      });
  }
}
