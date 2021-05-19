import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import initProjectVisibilitySelector from '../../../project_visibility';
import initProjectNew from '../../../projects/project_new';
import NewProjectCreationApp from './components/app.vue';

initProjectVisibilitySelector();
initProjectNew.bindEvents();

function initNewProjectCreation(el) {
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
    components: {
      NewProjectCreationApp,
    },
    provide,
    render(h) {
      return h(NewProjectCreationApp, { props });
    },
  });
}

const el = document.querySelector('.js-new-project-creation');

initNewProjectCreation(el);
