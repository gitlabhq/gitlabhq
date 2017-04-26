/* eslint-disable no-unused-vars */

class ListUser {
  constructor(user) {
    this.id = user.id;
    this.name = user.name;
    this.username = user.username;
    this.avatarUrl = user.avatar_url;
  }
}

window.ListUser = ListUser;
