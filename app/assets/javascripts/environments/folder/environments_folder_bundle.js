import Vue from 'vue';
import environmentsFolderApp from './environments_folder_view.vue';
import { parseBoolean } from '../../lib/utils/common_utils';
import Translate from '../../vue_shared/translate';

Vue.use(Translate);

export default () =>
  new Vue({
    el: '#environments-folder-list-view',
    components: {
      environmentsFolderApp,
    },
    data() {
      const environmentsData = document.querySelector(this.$options.el).dataset;

      return {
        endpoint: environmentsData.environmentsDataEndpoint,
        folderName: environmentsData.environmentsDataFolderName,
        cssContainerClass: environmentsData.cssClass,
        canCreateDeployment: parseBoolean(environmentsData.environmentsDataCanCreateDeployment),
        canReadEnvironment: parseBoolean(environmentsData.environmentsDataCanReadEnvironment),
      };
    },
    render(createElement) {
      return createElement('environments-folder-app', {
        props: {
          endpoint: this.endpoint,
          folderName: this.folderName,
          cssContainerClass: this.cssContainerClass,
          canCreateDeployment: this.canCreateDeployment,
          canReadEnvironment: this.canReadEnvironment,
        },
      });
    },
  });
