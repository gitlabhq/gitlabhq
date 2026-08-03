import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createApolloClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import csrf from '~/lib/utils/csrf';
import { TYPENAME_PROJECT, TYPENAME_GROUP } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import SidebarResizer from './components/sidebar_resizer.vue';
import WikiContentApp from './app.vue';
import initCache from './wiki_notes/graphql/cache_init';
import resolvers from './wiki_notes/graphql/resolvers';
import typeDefs from './wiki_notes/graphql/typedefs.graphql';

export const mountSidebarResizer = () => {
  const resizer = document.querySelector('.js-wiki-sidebar-resizer');

  if (resizer) {
    initVueApp({ el: resizer, name: 'SidebarResizerRoot', component: SidebarResizer });
  }
};

export const mountWikiApp = () => {
  const el = document.querySelector('#js-vue-wiki-app');

  if (!el) return false;
  const {
    pageHeading,
    contentApi,
    showEditButton,
    canCreateNewPage,
    showRestoreVersionButton,
    pageInfo,
    isPageTemplate,
    isPageHistorical,
    createFromTemplateUrl,
    lastVersion,
    pageVersion,
    authorUrl,
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

  return initVueApp({
    el,
    name: 'WikiContentAppRoot',
    apolloProvider,
    provide: {
      isEditingPath: false,
      pageHeading,
      contentApi,
      canCreateNewPage: parseBoolean(canCreateNewPage),
      showEditButton: parseBoolean(showEditButton),
      showRestoreVersionButton: parseBoolean(showRestoreVersionButton),
      pageInfo: pageInfoData,
      queryVariables,
      isPageTemplate: parseBoolean(isPageTemplate),
      isPageHistorical: parseBoolean(isPageHistorical),
      createFromTemplateUrl,
      lastVersion,
      pageVersion: JSON.parse(pageVersion),
      authorUrl,
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
      containerType,
      markdownPreviewPath,
      currentUserData: JSON.parse(currentUserData || {}),
      reportAbusePath,
      registerPath,
      signInPath,
      noteableType,
      noteCount: 5,
      markdownDocsPath: helpPagePath('user/markdown.md'),
      isContainerArchived: parseBoolean(isContainerArchived),
      containerName,
      pageAuthorEmail,
    },
    component: WikiContentApp,
  });
};
