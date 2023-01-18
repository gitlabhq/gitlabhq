import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import JobArtifactsTable from './components/job_artifacts_table.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export const initArtifactsTable = () => {
  const el = document.querySelector('#js-artifact-management');

  if (!el) {
    return false;
  }

  const { projectPath, canDestroyArtifacts, artifactsManagementFeedbackImagePath } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      projectPath,
      canDestroyArtifacts: parseBoolean(canDestroyArtifacts),
      artifactsManagementFeedbackImagePath,
    },
    render: (createElement) => createElement(JobArtifactsTable),
  });
};
