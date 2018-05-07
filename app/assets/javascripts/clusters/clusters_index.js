import createFlash from '~/flash';
import { __ } from '~/locale';
import setupToggleButtons from '~/toggle_buttons';
import gcpSignupOffer from '~/clusters/components/gcp_signup_offer';

import ClustersService from './services/clusters_service';

export default () => {
  const clusterList = document.querySelector('.js-clusters-list');

  gcpSignupOffer();

  // The empty state won't have a clusterList
  if (clusterList) {
    setupToggleButtons(document.querySelector('.js-clusters-list'), (value, toggle) =>
      ClustersService.updateCluster(toggle.dataset.endpoint, { cluster: { enabled: value } }).catch(
        err => {
          createFlash(__('Something went wrong on our end.'));
          throw err;
        },
      ),
    );
  }
};
