export default class Store {
  constructor({
    title,
    descriptionHtml,
    descriptionText,
  }) {
    this.state = {
      titleHtml: title,
      titleText: '',
      descriptionHtml,
      descriptionText,
      taskStatus: '',
      updatedAt: '',
    };
  }

  updateState(data) {
    this.state.titleHtml = data.title;
    this.state.titleText = data.title_text;
    this.state.descriptionHtml = data.description;
    this.state.descriptionText = data.description_text;
    this.state.taskStatus = data.task_status;
    this.state.updatedAt = data.updated_at;
  }
}
