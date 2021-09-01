import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import LearnGitlabA from '../components/learn_gitlab_a.vue';

function initLearnGitlab() {
  const el = document.getElementById('js-learn-gitlab-app');

  if (!el) {
    return false;
  }

  const actions = convertObjectPropsToCamelCase(JSON.parse(el.dataset.actions));
  const sections = convertObjectPropsToCamelCase(JSON.parse(el.dataset.sections));

  return new Vue({
    el,
    render(createElement) {
      return createElement(LearnGitlabA, {
        props: { actions, sections },
      });
    },
  });
}

initLearnGitlab();
