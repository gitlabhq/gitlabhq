export default class Store {
  constructor({
    titleHtml,
    titleText,
    descriptionHtml,
    descriptionText,
    updatedAt,
    updatedByName,
    updatedByPath,
  }) {
    this.state = {
      titleHtml,
      titleText,
      descriptionHtml,
      descriptionText,
      taskStatus: '',
      updatedAt,
      updatedByName,
      updatedByPath,
    };
    this.formState = {
      title: '',
      confidential: false,
      description: '',
      lockedWarningVisible: false,
      move_to_project_id: 0,
      updateLoading: false,
    };
  }

  updateState(data) {
    this.state.titleHtml = data.title;
    this.state.titleText = data.title_text;
    this.state.descriptionHtml = data.description;
    this.state.descriptionText = data.description_text;
    this.state.taskStatus = data.task_status;
    this.state.updatedAt = data.updated_at;
    this.state.updatedByName = data.updated_by_name;
    this.state.updatedByPath = data.updated_by_path;
  }

  stateShouldUpdate(data) {
    return {
      title: this.state.titleText !== data.title_text,
      description: this.state.descriptionText !== data.description_text,
    };
  }

  setFormState(state) {
    this.formState = Object.assign(this.formState, state);
  }
}
