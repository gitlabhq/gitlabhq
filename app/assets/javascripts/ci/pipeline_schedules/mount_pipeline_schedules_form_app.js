import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import PipelineSchedulesForm from './components/pipeline_schedules_form.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default (selector, editing = false) => {
  const containerEl = document.querySelector(selector);

  if (!containerEl) {
    return false;
  }

  const {
    canViewPipelineEditor,
    dailyLimit,
    defaultBranch,
    fullPath,
    pipelineEditorPath,
    projectId,
    schedulesPath,
    settingsLink,
    userRole,
    timezoneData,
  } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    name: 'PipelineSchedulesFormRoot',
    apolloProvider,
    provide: {
      canViewPipelineEditor: parseBoolean(canViewPipelineEditor),
      dailyLimit: dailyLimit ?? '',
      defaultBranch,
      fullPath,
      pipelineEditorPath,
      projectId,
      schedulesPath,
      settingsLink,
      userRole,
    },
    render(createElement) {
      return createElement(PipelineSchedulesForm, {
        props: {
          timezoneData: JSON.parse(timezoneData),
          refParam: defaultBranch,
          editing,
        },
      });
    },
  });
};
