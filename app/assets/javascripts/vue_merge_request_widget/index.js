import {
  Vue,
  mrWidgetOptions,
} from './dependencies';

document.addEventListener('DOMContentLoaded', () => {
  gl.mrWidgetData.gitlabLogo = gon.gitlab_logo;

  const vm = new Vue(mrWidgetOptions);

  window.gl.mrWidget = {
    checkStatus: vm.checkStatus,
  };
});
