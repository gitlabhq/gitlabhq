import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import Pages from './components/pages_pipeline_wizard.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(
    {},
    {
      batchMax: 1,
      assumeImmutableResults: true,
    },
  ),
});

export default function initPages() {
  const el = document.querySelector('#js-pages');

  if (!el) {
    return false;
  }

  return initVueApp({
    el,
    name: 'GitlabPagesNewRoot',
    apolloProvider,
    component: Pages,
    props: {
      ...el.dataset,
    },
  });
}
