import Vue from 'vue';
import MrWidgetOptions from './ee_switch_mr_widget_options';
import Translate from '../vue_shared/translate';

Vue.use(Translate);

export default () => {
  gl.mrWidgetData.gitlabLogo = gon.gitlab_logo;

  const vm = new Vue(MrWidgetOptions);

  window.gl.mrWidget = {
    checkStatus: vm.checkStatus,
  };
};
