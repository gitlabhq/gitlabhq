import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import LegacyPipelineNewForm from './components/legacy_pipeline_new_form.vue';
import PipelineNewForm from './components/pipeline_new_form.vue';
import { resolvers } from './graphql/resolvers';

const mountLegacyPipelineNewForm = (el) => {
  const {
    // provide/inject
    projectRefsEndpoint,

    // props
    configVariablesPath,
    defaultBranch,
    fileParam,
    maxWarnings,
    pipelinesPath,
    projectId,
    refParam,
    settingsLink,
    varParam,
  } = el.dataset;

  const variableParams = JSON.parse(varParam);
  const fileParams = JSON.parse(fileParam);

  return new Vue({
    el,
    provide: {
      projectRefsEndpoint,
    },
    render(createElement) {
      return createElement(LegacyPipelineNewForm, {
        props: {
          configVariablesPath,
          defaultBranch,
          fileParams,
          maxWarnings: Number(maxWarnings),
          pipelinesPath,
          projectId,
          refParam,
          settingsLink,
          variableParams,
        },
      });
    },
  });
};

const mountPipelineNewForm = (el) => {
  const {
    // provide/inject
    projectRefsEndpoint,

    // props
    defaultBranch,
    fileParam,
    maxWarnings,
    pipelinesPath,
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

  if (gon.features?.runPipelineGraphql) {
    mountPipelineNewForm(el);
  } else {
    mountLegacyPipelineNewForm(el);
  }
};
