import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import Translate from '~/vue_shared/translate';
import { apolloProvider } from '../graphql/client';
import EnvironmentsFolderView from './environments_folder_view.vue';
import EnvironmentsFolderApp from './environments_folder_app.vue';

Vue.use(Translate);
Vue.use(VueApollo);

const legacyApolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const el = document.getElementById('environments-folder-list-view');
  const environmentsData = el.dataset;
  if (gon.features.environmentsFolderNewLook) {
    const folderName = environmentsData.environmentsDataFolderName;
    const folderPath = environmentsData.environmentsDataEndpoint.replace('.json', '');
    const projectPath = environmentsData.environmentsDataProjectPath;
    const helpPagePath = environmentsData.environmentsDataHelpPagePath;

    return new Vue({
      el,
      components: {
        EnvironmentsFolderApp,
      },
      provide: {
        projectPath,
        helpPagePath,
      },
      apolloProvider,
      render(createElement) {
        return createElement('environments-folder-app', {
          props: {
            folderName,
            folderPath,
          },
        });
      },
    });
  }

  return new Vue({
    el,
    components: {
      EnvironmentsFolderView,
    },
    apolloProvider: legacyApolloProvider,
    provide: {
      projectPath: el.dataset.projectPath,
    },
    data() {
      return {
        endpoint: environmentsData.environmentsDataEndpoint,
        folderName: environmentsData.environmentsDataFolderName,
        cssContainerClass: environmentsData.cssClass,
      };
    },
    render(createElement) {
      return createElement('environments-folder-view', {
        props: {
          endpoint: this.endpoint,
          folderName: this.folderName,
          cssContainerClass: this.cssContainerClass,
        },
      });
    },
  });
};
