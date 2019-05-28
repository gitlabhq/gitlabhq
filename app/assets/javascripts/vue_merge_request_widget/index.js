import Vue from 'vue';
import MrWidgetOptions from 'ee_else_ce/vue_merge_request_widget/mr_widget_options.vue';
import Translate from '../vue_shared/translate';

Vue.use(Translate);

export default () => {
  gl.mrWidgetData.gitlabLogo = gon.gitlab_logo;

  const vm = new Vue(MrWidgetOptions);

  window.gl.mrWidget = {
    checkStatus: vm.checkStatus,
  };
};
