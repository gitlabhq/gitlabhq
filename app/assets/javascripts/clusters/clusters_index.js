import Flash from '../flash';
import { s__ } from '../locale';
import ClustersService from './services/clusters_service';

/**
 * Handles toggle buttons in the cluster's table.
 *
 * When the user clicks the toggle button for each cluster, it:
 * - toggles the button
 * - shows a loding and disabled state
 * - Makes a put request to the given endpoint
 * Once we receive the response, either:
 * 1) Show updated status in case of successfull response
 * 2) Show initial status in case of failed response
 */
export default class ClusterTable {
  constructor() {
    this.container = '.js-clusters-list';
    document.querySelectorAll(`${this.container} .js-toggle-cluster-list`).forEach(button => button.addEventListener('click', e => ClusterTable.updateCluster(e)));
  }

  removeListeners() {
    document.querySelectorAll(`${this.container} .js-toggle-cluster-list`).forEach(button => button.removeEventListener('click'));
  }

  static updateCluster(e) {
    const toggleButton = e.currentTarget;
    const value = toggleButton.classList.contains('checked').toString();
    const endpoint = toggleButton.getAttribute('data-endpoint');

    ClusterTable.toggleValue(toggleButton);
    ClusterTable.toggleLoadingButton(toggleButton);

    ClustersService.updateCluster(endpoint, { cluster: { enabled: value } })
      .then(() => {
        ClusterTable.toggleLoadingButton(toggleButton);
      })
      .catch(() => {
        ClusterTable.toggleLoadingButton(toggleButton);
        ClusterTable.toggleValue(toggleButton);
        Flash(s__('ClusterIntegration|Something went wrong on our end.'));
      });
  }

  /**
   * Toggles loading and disabled classes.
   * @param {HTMLElement} button
   */
  static toggleLoadingButton(button) {
    button.setAttribute('disabled', button.getAttribute('disabled'));
    button.classList.toggle('disabled');
    button.classList.toggle('loading');
  }

  /**
   * Toggles checked class for the given button
   * @param {HTMLElement} button
   */
  static toggleValue(button) {
    button.classList.toggle('checked');
  }
}
