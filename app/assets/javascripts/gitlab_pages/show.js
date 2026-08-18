import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
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

  return initVueApp({
    el,
    name: 'GitlabPagesEditRoot',
    apolloProvider,
    provide: {
      projectFullPath: el.dataset.fullPath,
      primaryDomain: el.dataset.primaryDomain,
    },
    component: PagesEdit,
  });
}
