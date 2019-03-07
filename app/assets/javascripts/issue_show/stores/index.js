import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export default class Store {
  constructor(initialState) {
    this.state = initialState;
    this.formState = {
      title: '',
      description: '',
      lockedWarningVisible: false,
      updateLoading: false,
      lock_version: 0,
    };
  }

  updateState(data) {
    if (this.stateShouldUpdate(data)) {
      this.formState.lockedWarningVisible = true;
    }

    Object.assign(this.state, convertObjectPropsToCamelCase(data));
    this.state.titleHtml = data.title;
    this.state.descriptionHtml = data.description;
    this.state.lock_version = data.lock_version;
  }

  stateShouldUpdate(data) {
    return (
      this.state.titleText !== data.title_text ||
      this.state.descriptionText !== data.description_text
    );
  }

  setFormState(state) {
    this.formState = Object.assign(this.formState, state);
  }
}
