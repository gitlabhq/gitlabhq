import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import App from './components/app.vue';

Vue.use(VueApollo);
Vue.use(GlToast);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export const initArtifactsTable = () => {
  const el = document.querySelector('#js-artifact-management');

  if (!el) {
    return false;
  }

  const {
    projectPath,
    projectId,
    canDestroyArtifacts,
    artifactsManagementFeedbackImagePath,
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      projectPath,
      projectId,
      canDestroyArtifacts: parseBoolean(canDestroyArtifacts),
      artifactsManagementFeedbackImagePath,
    },
    render: (createElement) => createElement(App),
  });
};
