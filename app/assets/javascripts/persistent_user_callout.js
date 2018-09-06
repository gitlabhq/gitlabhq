import axios from './lib/utils/axios_utils';
import { __ } from './locale';
import Flash from './flash';

export default class PersistentUserCallout {
  constructor(container) {
    const { dismissEndpoint, featureId } = container.dataset;
    this.container = container;
    this.dismissEndpoint = dismissEndpoint;
    this.featureId = featureId;
  }

  init() {
    const closeButton = this.container.querySelector('.js-close');
    closeButton.addEventListener('click', event => this.dismiss(event));
  }

  dismiss(event) {
    event.preventDefault();

    axios
      .post(this.dismissEndpoint, {
        feature_name: this.featureId,
      })
      .then(() => {
        this.container.remove();
      })
      .catch(() => {
        Flash(__('An error occurred while dismissing the alert. Refresh the page and try again.'));
      });
  }
}
