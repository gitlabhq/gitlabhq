import createFlash from '~/flash';
import { __ } from '~/locale';
import setupToggleButtons from '~/toggle_buttons';
import PersistentUserCallout from '../persistent_user_callout';

import ClustersService from './services/clusters_service';

export default () => {
  const clusterList = document.querySelector('.js-clusters-list');

  const callout = document.querySelector('.gcp-signup-offer');
  if (callout) new PersistentUserCallout(callout); // eslint-disable-line no-new

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
