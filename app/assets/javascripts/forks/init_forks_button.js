import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import ForksButton from './components/forks_button.vue';

const initForksButton = () => {
  const el = document.getElementById('js-forks-button');

  if (!el) {
    return false;
  }

  const {
    forksCount,
    projectFullPath,
    projectForksUrl,
    userForkUrl,
    newForkUrl,
    canReadCode,
    canCreateFork,
    canForkProject,
  } = el.dataset;

  return new Vue({
    el,
    provide: {
      forksCount,
      projectFullPath,
      projectForksUrl,
      userForkUrl,
      newForkUrl,
      canReadCode: parseBoolean(canReadCode),
      canCreateFork: parseBoolean(canCreateFork),
      canForkProject: parseBoolean(canForkProject),
    },
    render(createElement) {
      return createElement(ForksButton);
    },
  });
};

export default initForksButton;
