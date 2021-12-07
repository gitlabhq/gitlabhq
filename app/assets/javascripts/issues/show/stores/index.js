import { sanitize } from '~/lib/dompurify';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import updateDescription from '../utils/update_description';

export default class Store {
  constructor(initialState) {
    this.state = initialState;
    this.formState = {
      title: '',
      description: '',
      lockedWarningVisible: false,
      updateLoading: false,
      lock_version: 0,
      issuableTemplates: {},
    };
  }

  updateState(data) {
    if (this.stateShouldUpdate(data)) {
      this.formState.lockedWarningVisible = true;
    }

    Object.assign(this.state, convertObjectPropsToCamelCase(data));
    // find if there is an open details node inside of the issue description.
    const descriptionSection = document.body.querySelector(
      '.detail-page-description.content-block',
    );
    const details =
      descriptionSection != null && descriptionSection.getElementsByTagName('details');

    this.state.descriptionHtml = updateDescription(sanitize(data.description), details);
    this.state.titleHtml = sanitize(data.title);
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
