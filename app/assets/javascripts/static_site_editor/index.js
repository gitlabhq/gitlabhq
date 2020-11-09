import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import App from './components/app.vue';
import createRouter from './router';
import createApolloProvider from './graphql';

const initStaticSiteEditor = el => {
  const {
    isSupportedContent,
    path: sourcePath,
    baseUrl,
    branch,
    namespace,
    project,
    mergeRequestsIllustrationPath,
    // NOTE: The following variables are not yet used, but are supported by the config file,
    //       so we are adding them here as a convenience for future use.
    // eslint-disable-next-line no-unused-vars
    staticSiteGenerator,
    imageUploadPath,
    mounts,
  } = el.dataset;
  const { current_username: username } = window.gon;
  const returnUrl = el.dataset.returnUrl || null;
  const router = createRouter(baseUrl);
  const apolloProvider = createApolloProvider({
    isSupportedContent: parseBoolean(isSupportedContent),
    hasSubmittedChanges: false,
    project: `${namespace}/${project}`,
    mounts: JSON.parse(mounts), // NOTE that the object in 'mounts' is a JSON string from the data attribute, so it must be parsed into an object.
    branch,
    baseUrl,
    returnUrl,
    sourcePath,
    username,
    imageUploadPath,
  });

  return new Vue({
    el,
    router,
    apolloProvider,
    components: {
      App,
    },
    render(createElement) {
      return createElement('app', {
        props: {
          mergeRequestsIllustrationPath,
        },
      });
    },
  });
};

export default initStaticSiteEditor;
