import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import PipelineSchedulesForm from './components/pipeline_schedules_form.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default (selector) => {
  const containerEl = document.querySelector(selector);

  if (!containerEl) {
    return false;
  }

  const {
    fullPath,
    cron,
    dailyLimit,
    timezoneData,
    cronTimezone,
    projectId,
    defaultBranch,
    settingsLink,
  } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    name: 'PipelineSchedulesFormRoot',
    apolloProvider,
    provide: {
      fullPath,
      projectId,
      defaultBranch,
      dailyLimit: dailyLimit ?? '',
      cronTimezone: cronTimezone ?? '',
      cron: cron ?? '',
      settingsLink,
    },
    render(createElement) {
      return createElement(PipelineSchedulesForm, {
        props: {
          timezoneData: JSON.parse(timezoneData),
          refParam: defaultBranch,
        },
      });
    },
  });
};
