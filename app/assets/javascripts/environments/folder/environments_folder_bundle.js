import Vue from 'vue';
import environmentsFolderApp from './environments_folder_view.vue';
import { convertPermissionToBoolean } from '../../lib/utils/common_utils';
import Translate from '../../vue_shared/translate';

Vue.use(Translate);

export default () => new Vue({
  el: '#environments-folder-list-view',
  components: {
    environmentsFolderApp,
  },
  data() {
    const environmentsData = document.querySelector(this.$options.el).dataset;

    return {
      endpoint: environmentsData.endpoint,
      folderName: environmentsData.folderName,
      cssContainerClass: environmentsData.cssClass,
      canCreateDeployment: convertPermissionToBoolean(environmentsData.canCreateDeployment),
      canReadEnvironment: convertPermissionToBoolean(environmentsData.canReadEnvironment),
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
