import Flash from '../flash';
import { s__ } from '../locale';
import ClustersService from './services/clusters_service';
/**
 * Toggles loading and disabled classes.
 * @param {HTMLElement} button
 */
const toggleLoadingButton = (button) => {
  if (button.getAttribute('disabled')) {
    button.removeAttribute('disabled');
  } else {
    button.setAttribute('disabled', true);
  }

  button.classList.toggle('is-loading');
};

/**
 * Toggles checked class for the given button
 * @param {HTMLElement} button
 */
const toggleValue = (button) => {
  button.classList.toggle('is-checked');
};

/**
 * Handles toggle buttons in the cluster's table.
 *
 * When the user clicks the toggle button for each cluster, it:
 * - toggles the button
 * - shows a loading and disables button
 * - Makes a put request to the given endpoint
 * Once we receive the response, either:
 * 1) Show updated status in case of successfull response
 * 2) Show initial status in case of failed response
 */
export default function setClusterTableToggles() {
  document.querySelectorAll('.js-toggle-cluster-list')
    .forEach(button => button.addEventListener('click', (e) => {
      const toggleButton = e.currentTarget;
      const endpoint = toggleButton.getAttribute('data-endpoint');

      toggleValue(toggleButton);
      toggleLoadingButton(toggleButton);

      const value = toggleButton.classList.contains('is-checked');

      ClustersService.updateCluster(endpoint, { cluster: { enabled: value } })
        .then(() => {
          toggleLoadingButton(toggleButton);
        })
        .catch(() => {
          toggleLoadingButton(toggleButton);
          toggleValue(toggleButton);
          Flash(s__('ClusterIntegration|Something went wrong on our end.'));
        });
    }));
}
