import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';

import SnippetsShow from './components/show.vue';
import SnippetsEdit from './components/edit.vue';

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
  appFactory(document.getElementById('js-snippet-view'), SnippetsShow);
};

export const SnippetEditInit = () => {
  appFactory(document.getElementById('js-snippet-edit'), SnippetsEdit);
};

export default () => {};
