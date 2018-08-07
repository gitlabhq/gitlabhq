export default class ListMilestone {
  constructor(obj) {
    this.id = obj.id;
    this.title = obj.title;
    this.path = obj.path;
    this.state = obj.state;
    this.webUrl = obj.web_url || obj.webUrl;
    this.description = obj.description;
  }
}

window.ListMilestone = ListMilestone;
