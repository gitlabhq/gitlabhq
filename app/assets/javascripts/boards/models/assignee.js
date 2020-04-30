export default class ListAssignee {
  constructor(obj) {
    this.id = obj.id;
    this.name = obj.name;
    this.username = obj.username;
    this.avatar = obj.avatarUrl || obj.avatar_url || obj.avatar || gon.default_avatar_url;
    this.path = obj.path;
    this.state = obj.state;
    this.webUrl = obj.web_url || obj.webUrl;
  }
}

window.ListAssignee = ListAssignee;
