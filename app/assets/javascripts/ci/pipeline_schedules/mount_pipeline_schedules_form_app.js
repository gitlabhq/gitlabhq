import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
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
    dailyLimit,
    defaultBranch,
    projectId,
    projectPath,
    schedulesPath,
    settingsLink,
    canSetPipelineVariables,
    timezoneData,
    workerCronExpression,
  } = containerEl.dataset;

  return initVueApp({
    el: containerEl,
    name: 'PipelineSchedulesFormRoot',
    apolloProvider,
    provide: {
      dailyLimit: dailyLimit ?? '',
      defaultBranch,
      projectId,
      projectPath,
      schedulesPath,
      settingsLink,
      workerCronExpression,
    },
    component: PipelineSchedulesForm,
    props: {
      timezoneData: JSON.parse(timezoneData),
      editing,
      canSetPipelineVariables: parseBoolean(canSetPipelineVariables),
    },
  });
};
