export default class Store {
  constructor(initialState) {
    this.state = initialState;
    this.formState = {
      title: '',
      description: '',
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

  setFormState(state) {
    this.formState = Object.assign(this.formState, state);
  }
}
