import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';

import SnippetsApp from './components/show.vue';

Vue.use(VueApollo);
Vue.use(Translate);

function appFactory(el, Component) {
  if (!el) {
    return false;
  }

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      return createElement(Component, {
        props: {
          ...el.dataset,
        },
      });
    },
  });
}

export const SnippetShowInit = () => {
  appFactory(document.getElementById('js-snippet-view'), SnippetsApp);
};

export default () => {};
