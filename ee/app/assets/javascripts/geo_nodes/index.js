import Vue from 'vue';

import Translate from '~/vue_shared/translate';
import { convertPermissionToBoolean } from '~/lib/utils/common_utils';

import GeoNodesStore from './store/geo_nodes_store';
import GeoNodesService from './service/geo_nodes_service';

import geoNodesApp from './components/app.vue';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-geo-nodes');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    components: {
      geoNodesApp,
    },
    data() {
      const dataset = this.$options.el.dataset;
      const nodeActionsAllowed = convertPermissionToBoolean(dataset.nodeActionsAllowed);
      const nodeEditAllowed = convertPermissionToBoolean(dataset.nodeEditAllowed);
      const store = new GeoNodesStore(dataset.primaryVersion, dataset.primaryRevision);
      const service = new GeoNodesService();

      return {
        store,
        service,
        nodeActionsAllowed,
        nodeEditAllowed,
      };
    },
    render(createElement) {
      return createElement('geo-nodes-app', {
        props: {
          store: this.store,
          service: this.service,
          nodeActionsAllowed: this.nodeActionsAllowed,
          nodeEditAllowed: this.nodeEditAllowed,
        },
      });
    },
  });
};
