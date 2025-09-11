import VueApollo from 'vue-apollo';
import Vue from 'vue';
import createApolloClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_PROJECT, TYPENAME_GROUP } from '~/graphql_shared/constants';
import resolvers from './graphql/resolvers';
import typeDefs from './graphql/typedefs.graphql';
import initCache from './graphql/cache_init';
import WikiNotesApp from './components/wiki_notes_app.vue';

export default () => {
  const el = document.querySelector('#js-vue-wiki-notes-app');

  if (!el) return false;

  // TODO: create a locked wiki dicsussion docs path
  const {
    pageInfo,
    registerPath,
    signInPath,
    containerId,
    containerType,
    currentUserData,
    markdownPreviewPath,
    noteableType,
    isContainerArchived,
    notesFilters,
    reportAbusePath,
    containerName,
    pageAuthorEmail,
  } = el.dataset;

  if (!pageInfo) return false;

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
      pageInfo: pageInfoData,
      containerId,
      containerType,
      markdownPreviewPath,
      currentUserData: JSON.parse(currentUserData || {}),
      reportAbusePath,
      registerPath,
      signInPath,
      noteableType,
      queryVariables,
      noteCount: 5,
      markdownDocsPath: helpPagePath('user/markdown.md'),
      notesFilters: JSON.parse(notesFilters || {}),
      isContainerArchived: parseBoolean(isContainerArchived),
      containerName,
      pageAuthorEmail,
    },
    render(createElement) {
      return createElement(WikiNotesApp);
    },
  });
};
