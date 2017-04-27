/* eslint-disable no-unused-vars */

class ListAssignee {
  constructor(user) {
    this.id = user.id;
    this.name = user.name;
    this.username = user.username;
    this.avatarUrl = user.avatar_url;
  }
}

window.ListAssignee = ListAssignee;
