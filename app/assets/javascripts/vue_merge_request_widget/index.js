import Vue from 'vue';
import MrWidgetOptions from 'ee_else_ce/vue_merge_request_widget/mr_widget_options.vue';
import Translate from '../vue_shared/translate';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';

Vue.use(Translate);
Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  if (gl.mrWidget) return;

  gl.mrWidgetData.gitlabLogo = gon.gitlab_logo;
  gl.mrWidgetData.defaultAvatarUrl = gon.default_avatar_url;

  const vm = new Vue({ ...MrWidgetOptions, apolloProvider });

  window.gl.mrWidget = {
    checkStatus: vm.checkStatus,
  };
};
