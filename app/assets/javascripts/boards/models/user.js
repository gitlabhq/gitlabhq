/* eslint-disable no-unused-vars */
import defaultAvatar from '../utils/default_avatar';

class ListUser {
  constructor(user) {
    this.id = user.id;
    this.name = user.name;
    this.username = user.username;
    this.avatar = user.avatar_url || defaultAvatar();
  }
}

window.ListUser = ListUser;
