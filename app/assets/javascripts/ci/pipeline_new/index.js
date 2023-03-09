import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import PipelineNewForm from './components/pipeline_new_form.vue';
import { resolvers } from './graphql/resolvers';

const mountPipelineNewForm = (el) => {
  const {
    // provide/inject
    projectRefsEndpoint,

    // props
    defaultBranch,
    fileParam,
    maxWarnings,
    pipelinesPath,
    pipelinesEditorPath,
    canViewPipelineEditor,
    projectId,
    projectPath,
    refParam,
    settingsLink,
    varParam,
  } = el.dataset;

  const variableParams = JSON.parse(varParam);
  const fileParams = JSON.parse(fileParam);

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(resolvers),
  });

  return new Vue({
    el,
    apolloProvider,
    provide: {
      projectRefsEndpoint,
    },
    render(createElement) {
      return createElement(PipelineNewForm, {
        props: {
          defaultBranch,
          fileParams,
          maxWarnings: Number(maxWarnings),
          pipelinesPath,
          pipelinesEditorPath,
          canViewPipelineEditor,
          projectId,
          projectPath,
          refParam,
          settingsLink,
          variableParams,
        },
      });
    },
  });
};

export default () => {
  const el = document.getElementById('js-new-pipeline');

  mountPipelineNewForm(el);
};
