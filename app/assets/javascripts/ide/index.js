import Vue from 'vue';
import { mapActions } from 'vuex';
import { convertPermissionToBoolean } from '../lib/utils/common_utils';
import ide from './components/ide.vue';

import store from './stores';
import router from './ide_router';
import Translate from '../vue_shared/translate';
import ContextualSidebar from '../contextual_sidebar';

function initIde(el) {
  if (!el) return null;

  return new Vue({
    el,
    store,
    router,
    components: {
      ide,
    },
    methods: {
      ...mapActions([
        'setInitialData',
      ]),
    },
    created() {
      const data = el.dataset;

      this.setInitialData({
        endpoints: {
          rootEndpoint: data.url,
          newMergeRequestUrl: data.newMergeRequestUrl,
          rootUrl: data.rootUrl,
        },
        canCommit: convertPermissionToBoolean(data.canCommit),
        onTopOfBranch: convertPermissionToBoolean(data.onTopOfBranch),
        path: data.currentPath,
        isRoot: convertPermissionToBoolean(data.root),
        isInitialRoot: convertPermissionToBoolean(data.root),
      });
    },
    render(createElement) {
      return createElement('ide');
    },
  });
}

const ideElement = document.getElementById('ide');

Vue.use(Translate);

initIde(ideElement);

const contextualSidebar = new ContextualSidebar();
contextualSidebar.bindEvents();
