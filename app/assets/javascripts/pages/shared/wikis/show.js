import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createApolloClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import csrf from '~/lib/utils/csrf';
import Wikis from './wikis';
import WikiContentApp from './app.vue';
import WikiSidebarEntries from './components/wiki_sidebar_entries.vue';

const mountWikiContentApp = () => {
  const el = document.querySelector('#js-vue-wiki-content-app');

  if (!el) return false;
  const {
    pageHeading,
    contentApi,
    showEditButton,
    pageInfo,
    isPageTemplate,
    isPageHistorical,
    editButtonUrl,
    lastVersion,
    pageVersion,
    authorUrl,
    wikiPath,
    cloneSshUrl,
    cloneHttpUrl,
    newUrl,
    historyUrl,
    templatesUrl,
    wikiUrl,
    pagePersisted,
    templates,
    formatOptions,
  } = el.dataset;

  Vue.use(VueApollo);
  const apolloProvider = new VueApollo({ defaultClient: createApolloClient() });

  return new Vue({
    el,
    apolloProvider,
    provide: {
      isEditingPath: false,
      pageHeading,
      contentApi,
      showEditButton: parseBoolean(showEditButton),
      pageInfo: convertObjectPropsToCamelCase(JSON.parse(pageInfo)),
      isPageTemplate: parseBoolean(isPageTemplate),
      isPageHistorical: parseBoolean(isPageHistorical),
      editButtonUrl,
      lastVersion,
      pageVersion: JSON.parse(pageVersion),
      authorUrl,
      wikiPath,
      cloneSshUrl,
      cloneHttpUrl,
      newUrl,
      historyUrl,
      templatesUrl,
      wikiUrl,
      formatOptions: JSON.parse(formatOptions),
      csrfToken: csrf.token,
      templates: JSON.parse(templates),
      drawioUrl: gon.diagramsnet_url,
      pagePersisted: parseBoolean(pagePersisted),
    },
    render(createElement) {
      return createElement(WikiContentApp);
    },
  });
};

export const mountWikiSidebarEntries = () => {
  const el = document.querySelector('#js-wiki-sidebar-entries');
  if (!el) return false;

  const { hasCustomSidebar, canCreate, viewAllPagesPath } = el.dataset;

  return new Vue({
    el,
    provide: {
      hasCustomSidebar: parseBoolean(hasCustomSidebar),
      canCreate: parseBoolean(canCreate),
      sidebarPagesApi: gl.GfmAutoComplete.dataSources.wikis,
      viewAllPagesPath,
    },
    render(createElement) {
      return createElement(WikiSidebarEntries);
    },
  });
};

export const mountApplications = () => {
  mountWikiContentApp();

  new Wikis(); // eslint-disable-line no-new
};
