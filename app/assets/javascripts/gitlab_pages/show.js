import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { GlTabsBehavior, HISTORY_TYPE_HASH } from '~/tabs';
import PagesEdit from './components/edit.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default function initPages() {
  const el = document.querySelector('#js-pages');
  const pagesTabEl = document.querySelector('.js-pages-tabs');

  // eslint-disable-next-line no-new
  new GlTabsBehavior(pagesTabEl, { history: HISTORY_TYPE_HASH });

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    name: 'GitlabPagesEditRoot',
    apolloProvider,
    provide: {
      projectFullPath: el.dataset.fullPath,
    },
    render(createElement) {
      return createElement(PagesEdit, {});
    },
  });
}
