import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import AlertDetails from './components/alert_details.vue';

Vue.use(VueApollo);

export default selector => {
  const domEl = document.querySelector(selector);
  const { alertId, projectPath, newIssuePath } = domEl.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  // eslint-disable-next-line no-new
  new Vue({
    el: selector,
    apolloProvider,
    components: {
      AlertDetails,
    },
    render(createElement) {
      return createElement('alert-details', {
        props: {
          alertId,
          projectPath,
          newIssuePath,
        },
      });
    },
  });
};
