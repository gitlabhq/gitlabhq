import Vue from 'vue';
import LegacyPipelineNewForm from './components/legacy_pipeline_new_form.vue';
import PipelineNewForm from './components/pipeline_new_form.vue';

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

  // TODO: add apolloProvider

  return new Vue({
    el,
    provide: {
      projectRefsEndpoint,
    },
    render(createElement) {
      return createElement(PipelineNewForm, {
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

export default () => {
  const el = document.getElementById('js-new-pipeline');

  if (gon.features?.runPipelineGraphql) {
    mountPipelineNewForm(el);
  } else {
    mountLegacyPipelineNewForm(el);
  }
};
