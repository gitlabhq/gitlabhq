import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import store from './store';
import ErrorDetails from './components/error_details.vue';
import csrf from '~/lib/utils/csrf';

Vue.use(VueApollo);

export default () => {
  const selector = '#js-error_details';

  const domEl = document.querySelector(selector);
  const {
    issueId,
    projectPath,
    issueUpdatePath,
    issueStackTracePath,
    projectIssuesPath,
  } = domEl.dataset;

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
        },
      });
    },
  });
};
