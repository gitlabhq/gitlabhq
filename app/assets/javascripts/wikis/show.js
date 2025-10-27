import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createApolloClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import csrf from '~/lib/utils/csrf';
import { TYPENAME_PROJECT, TYPENAME_GROUP } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import SidebarResizer from './components/sidebar_resizer.vue';
import Wikis from './wikis';
import WikiContentApp from './app.vue';
import WikiSidebarEntries from './components/wiki_sidebar_entries.vue';
import initCache from './wiki_notes/graphql/cache_init';
import resolvers from './wiki_notes/graphql/resolvers';
import typeDefs from './wiki_notes/graphql/typedefs.graphql';

const mountSidebarResizer = () => {
  const resizer = document.querySelector('.js-wiki-sidebar-resizer');

  if (resizer) {
    // eslint-disable-next-line no-new
    new Vue({
      el: resizer,
      render: (createElement) => createElement(SidebarResizer),
    });
  }
};

const mountWikiApp = () => {
  const el = document.querySelector('#js-vue-wiki-app');

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
    containerId,
    containerType,
    registerPath,
    signInPath,
    currentUserData,
    markdownPreviewPath,
    noteableType,
    isContainerArchived,
    notesFilters,
    reportAbusePath,
    containerName,
    pageAuthorEmail,
  } = el.dataset;

  Vue.use(VueApollo);
  const apolloProvider = new VueApollo({
    defaultClient: createApolloClient(resolvers, { typeDefs }),
  });

  initCache(apolloProvider.defaultClient.cache);

  const pageInfoData = convertObjectPropsToCamelCase(JSON.parse(pageInfo));
  const queryVariables = {
    slug: pageInfoData.slug,
  };

  if (containerType === 'project') {
    queryVariables.projectId = convertToGraphQLId(TYPENAME_PROJECT, containerId);
  } else if (containerType === 'group') {
    queryVariables.namespaceId = convertToGraphQLId(TYPENAME_GROUP, containerId);
  }

  return new Vue({
    el,
    apolloProvider,
    provide: {
      isEditingPath: false,
      pageHeading,
      contentApi,
      showEditButton: parseBoolean(showEditButton),
      pageInfo: pageInfoData,
      queryVariables,
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
      containerId,
      containerType,
      markdownPreviewPath,
      currentUserData: JSON.parse(currentUserData || {}),
      reportAbusePath,
      registerPath,
      signInPath,
      noteableType,
      noteCount: 5,
      markdownDocsPath: helpPagePath('user/markdown.md'),
      notesFilters: JSON.parse(notesFilters || {}),
      isContainerArchived: parseBoolean(isContainerArchived),
      containerName,
      pageAuthorEmail,
    },
    render(createElement) {
      return createElement(WikiContentApp);
    },
  });
};

export const mountWikiSidebarEntries = () => {
  const el = document.querySelector('#js-wiki-sidebar-entries');
  if (!el) return false;

  const { hasCustomSidebar, canCreate, viewAllPagesPath, editing } = el.dataset;

  return new Vue({
    el,
    provide: {
      hasCustomSidebar: parseBoolean(hasCustomSidebar),
      canCreate: parseBoolean(canCreate),
      sidebarPagesApi: gl.GfmAutoComplete.dataSources.wikis,
      viewAllPagesPath,
      editing,
    },
    render(createElement) {
      return createElement(WikiSidebarEntries);
    },
  });
};

export const mountApplications = () => {
  mountWikiApp();
  mountSidebarResizer();

  new Wikis(); // eslint-disable-line no-new
};
