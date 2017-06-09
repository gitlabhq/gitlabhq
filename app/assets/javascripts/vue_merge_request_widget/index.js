import {
  Vue,
  mrWidgetOptions,
} from './dependencies';

document.addEventListener('DOMContentLoaded', () => {
<<<<<<< HEAD
=======
  gl.mrWidgetData.gitlabLogo = gon.gitlab_logo;

>>>>>>> abc61f260074663e5711d3814d9b7d301d07a259
  const vm = new Vue(mrWidgetOptions);

  window.gl.mrWidget = {
    checkStatus: vm.checkStatus,
  };
});
