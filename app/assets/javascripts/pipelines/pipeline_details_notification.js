import Vue from 'vue';
import VueApollo from 'vue-apollo';
import DeprecatedKeywordNotification from './components/notification/deprecated_type_keyword_notification.vue';

Vue.use(VueApollo);

export const createPipelineNotificationApp = (elSelector, apolloProvider) => {
  const el = document.querySelector(elSelector);

  if (!el) {
    return;
  }

  const { deprecatedKeywordsDocPath, fullPath, pipelineIid } = el?.dataset;
  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      DeprecatedKeywordNotification,
    },
    provide: {
      deprecatedKeywordsDocPath,
      fullPath,
      pipelineIid,
    },
    apolloProvider,
    render(createElement) {
      return createElement('deprecated-keyword-notification');
    },
  });
};
