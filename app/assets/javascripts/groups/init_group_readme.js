import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import apolloProvider from '~/repository/graphql';
import FilePreview from '~/repository/components/preview/index.vue';

Vue.use(VueApollo);

export const initGroupReadme = () => {
  const el = document.getElementById('js-group-readme');

  if (!el) return false;

  const { webPath, name } = el.dataset;

  return initVueApp({
    el,
    name: 'GroupFilePreviewRoot',
    apolloProvider,
    component: FilePreview,
    props: {
      blob: { webPath, name },
    },
  });
};
