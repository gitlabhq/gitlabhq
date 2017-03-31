import {
  Vue,
  mrWidgetOptions,
} from './dependencies';

document.addEventListener('DOMContentLoaded', () => {
  const vm = new Vue(mrWidgetOptions);

  window.gl.mrWidget = {
    checkStatus: vm.checkStatus,
  };
});
