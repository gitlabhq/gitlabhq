import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import PipelineSchedules from './components/pipeline_schedules.vue';

Vue.use(VueApollo);
Vue.use(GlToast);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const containerEl = document.querySelector('#pipeline-schedules-app');

  if (!containerEl) {
    return false;
  }

  const { fullPath, pipelinesPath, newSchedulePath, schedulesPath } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    name: 'PipelineSchedulesRoot',
    apolloProvider,
    provide: {
      fullPath,
      pipelinesPath,
      newSchedulePath,
      schedulesPath,
    },
    render(createElement) {
      return createElement(PipelineSchedules);
    },
  });
};
