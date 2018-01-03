/* eslint-disable no-unused-vars */

class ListAssignee {
  constructor(user, defaultAvatar) {
    this.id = user.id;
    this.name = user.name;
    this.username = user.username;
    this.avatar = user.avatar_url || defaultAvatar;
  }
}

window.ListAssignee = ListAssignee;
