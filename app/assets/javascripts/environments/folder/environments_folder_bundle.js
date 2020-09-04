import Vue from 'vue';
import VueApollo from 'vue-apollo';
import canaryCalloutMixin from '../mixins/canary_callout_mixin';
import environmentsFolderApp from './environments_folder_view.vue';
import { parseBoolean } from '../../lib/utils/common_utils';
import Translate from '../../vue_shared/translate';
import createDefaultClient from '~/lib/graphql';

Vue.use(Translate);
Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const el = document.getElementById('environments-folder-list-view');

  return new Vue({
    el,
    components: {
      environmentsFolderApp,
    },
    mixins: [canaryCalloutMixin],
    apolloProvider,
    provide: {
      projectPath: el.dataset.projectPath,
    },
    data() {
      const environmentsData = el.dataset;

      return {
        endpoint: environmentsData.environmentsDataEndpoint,
        folderName: environmentsData.environmentsDataFolderName,
        cssContainerClass: environmentsData.cssClass,
        canReadEnvironment: parseBoolean(environmentsData.environmentsDataCanReadEnvironment),
      };
    },
    render(createElement) {
      return createElement('environments-folder-app', {
        props: {
          endpoint: this.endpoint,
          folderName: this.folderName,
          cssContainerClass: this.cssContainerClass,
          canReadEnvironment: this.canReadEnvironment,
          ...this.canaryCalloutProps,
        },
      });
    },
  });
};
