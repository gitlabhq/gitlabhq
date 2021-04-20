import Vue from 'vue';
import VueApollo from 'vue-apollo';
import PipelineNotification from './components/notification/pipeline_notification.vue';

Vue.use(VueApollo);

export const createPipelineNotificationApp = (elSelector, apolloProvider) => {
  const el = document.querySelector(elSelector);

  if (!el) {
    return;
  }

  const { dagDocPath } = el?.dataset;
  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      PipelineNotification,
    },
    provide: {
      dagDocPath,
    },
    apolloProvider,
    render(createElement) {
      return createElement('pipeline-notification');
    },
  });
};
