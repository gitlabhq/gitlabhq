import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import StorageCounterApp from './components/app.vue';

Vue.use(VueApollo);

export default (containerId = 'js-project-storage-count-app') => {
  const el = document.getElementById(containerId);

  if (!el) {
    return false;
  }

  const {
    projectPath,
    usageQuotasHelpPagePath,
    buildArtifactsHelpPagePath,
    lfsObjectsHelpPagePath,
    packagesHelpPagePath,
    repositoryHelpPagePath,
    snippetsHelpPagePath,
    uploadsHelpPagePath,
    wikiHelpPagePath,
  } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    provide: {
      projectPath,
      helpLinks: {
        usageQuotasHelpPagePath,
        buildArtifactsHelpPagePath,
        lfsObjectsHelpPagePath,
        packagesHelpPagePath,
        repositoryHelpPagePath,
        snippetsHelpPagePath,
        uploadsHelpPagePath,
        wikiHelpPagePath,
      },
    },
    render(createElement) {
      return createElement(StorageCounterApp);
    },
  });
};
