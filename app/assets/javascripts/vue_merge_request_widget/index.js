import Vue from 'vue';
import MrWidgetOptions from 'ee_else_ce/vue_merge_request_widget/mr_widget_options.vue';
import VueApollo from 'vue-apollo';
import Translate from '../vue_shared/translate';
import createDefaultClient from '~/lib/graphql';
import { registerExtension } from './components/extensions';
import issueExtension from './extensions/issues';

Vue.use(Translate);
Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(
    {},
    {
      assumeImmutableResults: true,
    },
  ),
});

export default () => {
  if (gl.mrWidget) return;

  gl.mrWidgetData.gitlabLogo = gon.gitlab_logo;
  gl.mrWidgetData.defaultAvatarUrl = gon.default_avatar_url;

  registerExtension(issueExtension);

  const vm = new Vue({ ...MrWidgetOptions, apolloProvider });

  window.gl.mrWidget = {
    checkStatus: vm.checkStatus,
  };
};
