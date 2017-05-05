<<<<<<< HEAD:app/assets/javascripts/boards/models/assignee.js
/* eslint-disable no-unused-vars */

class ListAssignee {
  constructor(user) {
    this.id = user.id;
    this.name = user.name;
    this.username = user.username;
    this.avatarUrl = user.avatar_url;
=======
class ListUser {
  constructor(user, defaultAvatar) {
    this.id = user.id;
    this.name = user.name;
    this.username = user.username;
    this.avatar = user.avatar_url || defaultAvatar;
>>>>>>> 10c1bf2d77fd0ab21309d0b136cbc0ac11f56c77:app/assets/javascripts/boards/models/user.js
  }
}

window.ListAssignee = ListAssignee;
