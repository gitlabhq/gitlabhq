import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import PagesEdit from './components/pages_edit.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default function initPages() {
  const el = document.querySelector('#js-pages');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    name: 'GitlabPagesEditRoot',
    apolloProvider,
    render(createElement) {
      return createElement(PagesEdit, {
        props: {
          ...el.dataset,
        },
      });
    },
  });
}
