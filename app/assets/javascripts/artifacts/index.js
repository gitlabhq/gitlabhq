import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
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

  const { projectPath } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      projectPath,
    },
    render: (createElement) => createElement(JobArtifactsTable),
  });
};
