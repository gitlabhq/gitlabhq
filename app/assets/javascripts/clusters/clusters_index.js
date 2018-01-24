import Flash from '../flash';
import { s__ } from '../locale';
import ToggleButton from '../toggle_button';
import ClustersService from './services/clusters_service';

export default () => {
  document.querySelectorAll('.js-project-feature-toggle').forEach((toggle) => {
    const endpoint = toggle.dataset.endpoint;

    const toggleButton = new ToggleButton(
      toggle,
      value =>
        ClustersService.updateCluster(endpoint, { cluster: { enabled: value } })
          .catch((err) => {
            Flash(s__('ClusterIntegration|Something went wrong on our end.'));
            throw err;
          }),
    );
    toggleButton.init();
  });
};
