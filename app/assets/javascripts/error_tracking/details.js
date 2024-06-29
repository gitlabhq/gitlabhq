import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import csrf from '~/lib/utils/csrf';
import { parseBoolean } from '~/lib/utils/common_utils';
import ErrorDetails from './components/error_details.vue';
import store from './store';

Vue.use(VueApollo);

export default () => {
  const selector = '#js-error_details';

  const domEl = document.querySelector(selector);
  const { issueId, projectPath, issueUpdatePath, issueStackTracePath, projectIssuesPath } =
    domEl.dataset;

  let { integratedErrorTrackingEnabled } = domEl.dataset;
  integratedErrorTrackingEnabled = parseBoolean(integratedErrorTrackingEnabled);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  // eslint-disable-next-line no-new
  new Vue({
    el: selector,
    apolloProvider,
    components: {
      ErrorDetails,
    },
    store,
    render(createElement) {
      return createElement('error-details', {
        props: {
          issueId,
          projectPath,
          issueUpdatePath,
          issueStackTracePath,
          projectIssuesPath,
          csrfToken: csrf.token,
          integratedErrorTrackingEnabled,
        },
      });
    },
  });
};
