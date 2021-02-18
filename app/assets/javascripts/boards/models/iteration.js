export default class ListIteration {
  constructor(obj) {
    this.id = obj.id;
    this.title = obj.title;
    this.state = obj.state;
    this.webUrl = obj.web_url || obj.webUrl;
    this.description = obj.description;
  }
}
