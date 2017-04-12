/* global Flash */
import '~/flash';

export default class SidebarAssigneesStore {
  constructor(store) {
    const { currentUser, assignees, rootPath, editable } = store;

    this.currentUser = currentUser;
    this.rootPath = rootPath;
    this.users = [];
    this.loading = false;
    this.editable = editable;
    this.defaultRenderCount = 5;

    assignees.forEach(a => this.addUser(this.destructUser(a)));
  }

  addUser(user) {
    const { id, name, username, avatarUrl } = user;

    this.users.push({
      id,
      name,
      username,
      avatarUrl,
    });
    console.log(`addUser()`);
    console.log(user);
  }

  addCurrentUser() {
    this.addUser(this.currentUser);
  }

  removeUser(id) {
    console.log(`removeUser()`);
    console.log(id);
    this.users = this.users.filter(u => u.id !== id);
  }

  removeAllUsers() {
    this.users = [];
  }

  getUserIds() {
    console.log(`getUserIds`);
    const ids = this.users.map(u => u.id);

    if (ids.length > 0 && ids[0] == undefined) {
      debugger
    }
    // If there are no ids, that means we have to unassign (which is id = 0)
    return ids.length > 0 ? ids : [0];
  }

  destructUser(u) {
    return {
      id: u.id,
      name: u.name,
      username: u.username,
      avatarUrl: u.avatar_url,
    };
  }

  saveUsers(assignees) {
    this.users = [];

    assignees.forEach(a => this.addUser(this.destructUser(a)));
  }
}
