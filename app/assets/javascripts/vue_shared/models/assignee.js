export default class ListAssignee {
  constructor(obj, defaultAvatar) {
    this.id = obj.id;
    this.name = obj.name;
    this.username = obj.username;
    this.avatar = obj.avatar_url || obj.avatar || defaultAvatar;
    this.path = obj.path;
    this.state = obj.state;
    this.webUrl = obj.web_url || obj.webUrl;
  }
}

window.ListAssignee = ListAssignee;
