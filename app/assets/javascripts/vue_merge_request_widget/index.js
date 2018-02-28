import {
  Vue,
  mrWidgetOptions,
} from './dependencies';
import Translate from '../vue_shared/translate';

Vue.use(Translate);

document.addEventListener('DOMContentLoaded', () => {
  gl.mrWidgetData.gitlabLogo = gon.gitlab_logo;

  const vm = new Vue(mrWidgetOptions);

  window.gl.mrWidget = {
    checkStatus: vm.checkStatus,
  };
});
