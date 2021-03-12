import Vue from 'vue';
import PipelineNewForm from './components/pipeline_new_form.vue';

export default () => {
  const el = document.getElementById('js-new-pipeline');
  const {
    // provide/inject
    projectRefsEndpoint,

    // props
    projectId,
    pipelinesPath,
    configVariablesPath,
    defaultBranch,
    refParam,
    varParam,
    fileParam,
    settingsLink,
    maxWarnings,
  } = el?.dataset;

  const variableParams = JSON.parse(varParam);
  const fileParams = JSON.parse(fileParam);

  return new Vue({
    el,
    provide: {
      projectRefsEndpoint,
    },
    render(createElement) {
      return createElement(PipelineNewForm, {
        props: {
          projectId,
          pipelinesPath,
          configVariablesPath,
          defaultBranch,
          refParam,
          variableParams,
          fileParams,
          settingsLink,
          maxWarnings: Number(maxWarnings),
        },
      });
    },
  });
};
