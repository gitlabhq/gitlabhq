import Vue from 'vue';
import trackLearnGitlab from '~/learn_gitlab/track_learn_gitlab';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import LearnGitlabA from '../components/learn_gitlab_a.vue';
import LearnGitlabB from '../components/learn_gitlab_b.vue';

function initLearnGitlab() {
  const el = document.getElementById('js-learn-gitlab-app');

  if (!el) {
    return false;
  }

  const actions = convertObjectPropsToCamelCase(JSON.parse(el.dataset.actions));
  const sections = convertObjectPropsToCamelCase(JSON.parse(el.dataset.sections));

  const { learnGitlabA } = gon.experiments;

  trackLearnGitlab(learnGitlabA);

  return new Vue({
    el,
    render(createElement) {
      return createElement(learnGitlabA ? LearnGitlabA : LearnGitlabB, {
        props: { actions, sections },
      });
    },
  });
}

initLearnGitlab();
