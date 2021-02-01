import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '../../lib/utils/common_utils';
import Translate from '../../vue_shared/translate';
import environmentsFolderApp from './environments_folder_view.vue';

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
        },
      });
    },
  });
};
