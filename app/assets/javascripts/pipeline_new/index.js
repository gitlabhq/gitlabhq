import Vue from 'vue';
import PipelineNewForm from './components/pipeline_new_form.vue';
import formatRefs from './utils/format_refs';

export default () => {
  const el = document.getElementById('js-new-pipeline');
  const {
    projectId,
    pipelinesPath,
    configVariablesPath,
    defaultBranch,
    refParam,
    varParam,
    fileParam,
    branchRefs,
    tagRefs,
    settingsLink,
    maxWarnings,
  } = el?.dataset;

  const variableParams = JSON.parse(varParam);
  const fileParams = JSON.parse(fileParam);
  const branches = formatRefs(JSON.parse(branchRefs), 'branch');
  const tags = formatRefs(JSON.parse(tagRefs), 'tag');

  return new Vue({
    el,
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
          branches,
          tags,
          settingsLink,
          maxWarnings: Number(maxWarnings),
        },
      });
    },
  });
};
