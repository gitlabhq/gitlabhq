import VueApollo from 'vue-apollo';
import Vue from 'vue';
import createApolloClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { helpPagePath } from '~/helpers/help_page_helper';
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

  return new Vue({
    el,
    apolloProvider,
    provide: {
      pageInfo: convertObjectPropsToCamelCase(JSON.parse(pageInfo)),
      containerId,
      containerType,
      markdownPreviewPath,
      currentUserData: JSON.parse(currentUserData || {}),
      reportAbusePath,
      registerPath,
      signInPath,
      noteableType,
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
