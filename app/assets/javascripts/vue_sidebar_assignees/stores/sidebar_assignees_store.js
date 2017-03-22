export default class SidebarAssigneesStore {
  constructor(currentUserId, service) {
    this.currentUserId = currentUserId;
    this.service = service;
    this.users = [];
  }

  addUser(name, username, avatarUrl) {
    this.users.push({
      avatarUrl,
      name,
      username,
    });
  }

  addUserIds(ids) {
    this.service.add(ids).then((response) => {
        const data = response.data;
        const assignee = data.assignee;

        if (assignee) {
          this.addUser(assignee.name, assignee.username, assignee.avatar_url);
        } else {
          this.users = [];
        }
      }).catch((err) => {
        console.log(err);
        console.log('error');
      });
  }

  addCurrentUser() {
    this.addUserIds(this.currentUserId);
  }

  removeUser(username) {
    this.users = this.users.filter((u) => u.username !== username);
  }
}