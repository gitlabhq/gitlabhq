import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import initProjectVisibilitySelector from '../../../project_visibility';
import initProjectNew from '../../../projects/project_new';
import NewProjectCreationApp from './components/app.vue';
import NewProjectUrlSelect from './components/new_project_url_select.vue';

function initNewProjectCreation() {
  const el = document.querySelector('.js-new-project-creation');

  const {
    pushToCreateProjectCommand,
    workingWithProjectsHelpPath,
    newProjectGuidelines,
    hasErrors,
    isCiCdAvailable,
  } = el.dataset;

  const props = {
    hasErrors: parseBoolean(hasErrors),
    isCiCdAvailable: parseBoolean(isCiCdAvailable),
    newProjectGuidelines,
  };

  const provide = {
    workingWithProjectsHelpPath,
    pushToCreateProjectCommand,
  };

  return new Vue({
    el,
    provide,
    render(h) {
      return h(NewProjectCreationApp, { props });
    },
  });
}

function initNewProjectUrlSelect() {
  const el = document.querySelector('.js-vue-new-project-url-select');

  if (!el) {
    return undefined;
  }

  Vue.use(VueApollo);

  return new Vue({
    el,
    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient({}, { assumeImmutableResults: true }),
    }),
    provide: {
      namespaceFullPath: el.dataset.namespaceFullPath,
      namespaceId: el.dataset.namespaceId,
      rootUrl: el.dataset.rootUrl,
      trackLabel: el.dataset.trackLabel,
    },
    render: (createElement) => createElement(NewProjectUrlSelect),
  });
}

initProjectVisibilitySelector();
initProjectNew.bindEvents();
initNewProjectCreation();
initNewProjectUrlSelect();
