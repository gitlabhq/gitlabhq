import Vue from 'vue';
import canaryCalloutMixin from '../mixins/canary_callout_mixin';
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
    mixins: [canaryCalloutMixin],
    data() {
      const environmentsData = document.querySelector(this.$options.el).dataset;

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
