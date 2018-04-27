export default class ListLabel {
  constructor(obj) {
    this.id = obj.id;
    this.title = obj.title;
    this.type = obj.type;
    this.color = obj.color;
    this.textColor = obj.text_color;
    this.description = obj.description;
    this.priority = (obj.priority !== null) ? obj.priority : Infinity;
  }
}

window.ListLabel = ListLabel;
