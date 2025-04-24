import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import PipelineNewForm from './components/pipeline_new_form.vue';

const mountPipelineNewForm = (el) => {
  const {
    // provide/inject
    canViewPipelineEditor,
    identityVerificationPath,
    pipelineEditorPath,
    pipelinesPath,
    projectPath,
    projectRefsEndpoint,
    userRole,
    canSetPipelineVariables,

    // props
    defaultBranch,
    fileParam,
    maxWarnings,
    projectId,
    refParam,
    settingsLink,
    varParam,
  } = el.dataset;

  const variableParams = JSON.parse(varParam);
  const fileParams = JSON.parse(fileParam);

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    provide: {
      canViewPipelineEditor: parseBoolean(canViewPipelineEditor),
      canSetPipelineVariables: parseBoolean(canSetPipelineVariables),
      identityVerificationPath,
      // Normally this will have a value from a helper. In this case, this is
      // set to true because the alert that uses this field is dynamically
      // rendered if a specific error is returned from the backend after
      // the create pipeline XHR request completes
      identityVerificationRequired: true,
      pipelineEditorPath,
      pipelinesPath,
      projectPath,
      projectRefsEndpoint,
      userRole,
    },
    render(createElement) {
      return createElement(PipelineNewForm, {
        props: {
          defaultBranch,
          fileParams,
          maxWarnings: Number(maxWarnings),
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

  mountPipelineNewForm(el);
};
