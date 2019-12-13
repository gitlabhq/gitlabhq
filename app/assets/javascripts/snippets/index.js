import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';

import SnippetsApp from './components/app.vue';

Vue.use(VueApollo);
Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-snippet-view');

  if (!el) {
    return false;
  }

  const { snippetGid } = el.dataset;
  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      return createElement(SnippetsApp, {
        props: {
          snippetGid,
        },
      });
    },
  });
};
