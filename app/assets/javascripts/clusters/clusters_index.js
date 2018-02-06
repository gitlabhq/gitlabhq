import Flash from '../flash';
import { s__ } from '../locale';
import setupToggleButtons from '../toggle_buttons';
import ClustersService from './services/clusters_service';

export default () => {
  const clusterList = document.querySelector('.js-clusters-list');
  // The empty state won't have a clusterList
  if (clusterList) {
    setupToggleButtons(
      document.querySelector('.js-clusters-list'),
      (value, toggle) =>
        ClustersService.updateCluster(toggle.dataset.endpoint, { cluster: { enabled: value } })
          .catch((err) => {
            Flash(s__('ClusterIntegration|Something went wrong on our end.'));
            throw err;
          }),
    );
  }
};
