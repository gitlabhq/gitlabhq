import Vue from 'vue';
import PipelineNewForm from './components/pipeline_new_form.vue';

export default () => {
  const el = document.getElementById('js-new-pipeline');
  const {
    projectId,
    pipelinesPath,
    configVariablesPath,
    refParam,
    varParam,
    fileParam,
    refNames,
    settingsLink,
    maxWarnings,
  } = el?.dataset;

  const variableParams = JSON.parse(varParam);
  const fileParams = JSON.parse(fileParam);
  const refs = JSON.parse(refNames);

  return new Vue({
    el,
    render(createElement) {
      return createElement(PipelineNewForm, {
        props: {
          projectId,
          pipelinesPath,
          configVariablesPath,
          refParam,
          variableParams,
          fileParams,
          refs,
          settingsLink,
          maxWarnings: Number(maxWarnings),
        },
      });
    },
  });
};
