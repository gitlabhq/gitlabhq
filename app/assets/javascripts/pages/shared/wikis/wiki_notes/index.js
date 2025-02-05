import VueApollo from 'vue-apollo';
import Vue from 'vue';
import createApolloClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_PROJECT, TYPENAME_GROUP } from '~/graphql_shared/constants';
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
  } = el.dataset;

  if (!pageInfo) return false;

  Vue.use(VueApollo);
  const apolloProvider = new VueApollo({ defaultClient: createApolloClient() });

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
      lockedWikiDocsPath: '',
      markdownDocsPath: helpPagePath('user/markdown.md'),
      archivedProjectDocsPath: helpPagePath('user/project/working_with_projects.md', {
        anchor: 'archive-a-project',
      }),
      notesFilters: JSON.parse(notesFilters || {}),
      isContainerArchived: isContainerArchived === undefined ? false : isContainerArchived !== null,
    },
    render(createElement) {
      return createElement(WikiNotesApp);
    },
  });
};
