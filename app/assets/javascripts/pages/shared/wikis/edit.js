import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createApolloClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import csrf from '~/lib/utils/csrf';
import ZenMode from '~/zen_mode';
import WikiContentApp from './app.vue';

const mountWikiEditApp = () => {
  const el = document.querySelector('#js-vue-wiki-edit-app');

  if (!el) return false;
  const {
    pageHeading,
    pageInfo,
    isPageTemplate,
    wikiUrl,
    pagePersisted,
    templates,
    formatOptions,
    error,
    templatesUrl,
  } = el.dataset;

  Vue.use(VueApollo);
  const apolloProvider = new VueApollo({ defaultClient: createApolloClient() });

  return new Vue({
    el,
    apolloProvider,
    provide: {
      isEditingPath: true,
      pageHeading,
      pageInfo: convertObjectPropsToCamelCase(JSON.parse(pageInfo)),
      isPageTemplate: parseBoolean(isPageTemplate),
      isPageHistorical: false,
      formatOptions: JSON.parse(formatOptions),
      csrfToken: csrf.token,
      templates: JSON.parse(templates),
      drawioUrl: gon.diagramsnet_url,
      wikiUrl,
      pagePersisted: parseBoolean(pagePersisted),
      templatesUrl,
      error,
    },
    render(createElement) {
      return createElement(WikiContentApp);
    },
  });
};

export const mountApplications = () => {
  new ZenMode(); // eslint-disable-line no-new
  mountWikiEditApp();
};
